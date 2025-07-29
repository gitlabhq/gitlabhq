# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GroupMentionService, feature_category: :integrations do
  subject(:execute) { described_class.new(mentionable, hook_data: hook_data, is_confidential: is_confidential).execute }

  let(:group_mention_access_check_ff_enabled) { nil }

  let_it_be(:author) { create(:user) }
  let_it_be(:member) { create(:user) }
  let_it_be(:group_1) { create(:group) }
  let_it_be(:group_2) { create(:group) }
  let_it_be(:group_3) { create(:group) }
  let_it_be(:groups) { nil }
  let_it_be(:all_groups) { [group_1, group_2, group_3] }
  let_it_be(:groups_with_integrations) { [group_1, group_2] }
  let_it_be(:public_project_with_group) { create(:project, :public) }
  let_it_be(:public_project_without_group) { create(:project, :public) }
  let_it_be(:private_project_with_group) { create(:project, :private) }
  let_it_be(:private_project_without_group) { create(:project, :private) }

  before_all do
    group_1.add_developer(member)
    create(:integrations_slack, :group, group: group_1, group_mention_events: true,
      group_confidential_mention_events: true)
    create(:project_group_link, :developer, project: public_project_with_group, group: group_1)
    create(:project_group_link, :developer, project: private_project_with_group, group: group_1)

    group_2.add_developer(member)
    create(:integrations_slack, :group, group: group_2, group_mention_events: true,
      group_confidential_mention_events: true)
    create(:project_group_link, :developer, project: public_project_with_group, group: group_2)
    create(:project_group_link, :developer, project: private_project_with_group, group: group_2)
  end

  before do
    allow(mentionable).to receive(:referenced_groups).with(author).and_return(groups)
    stub_feature_flags(group_mention_access_check: group_mention_access_check_ff_enabled)
  end

  shared_examples 'public_group_mention_hooks' do
    context "when the 'group_mention_access_check' feature flag is disabled" do
      let(:groups) { all_groups }
      let(:group_mention_access_check_ff_enabled) { false }

      specify do
        allow(Gitlab::Metrics).to receive(:measure).and_call_original
        expect(Gitlab::Metrics).to receive(:measure).with(:integrations_group_mention_execution).and_call_original

        expect(groups).not_to receive(:with_integrations)

        expect(group_1).to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_1).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(group_2).to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_2).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(group_3).to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_3).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(execute).to be_success
      end
    end

    context "when the 'group_mention_access_check' feature flag is enabled" do
      let(:groups) { groups_with_integrations }
      let(:group_mention_access_check_ff_enabled) { true }

      specify do
        allow(Gitlab::Metrics).to receive(:measure).and_call_original
        expect(Gitlab::Metrics).to receive(:measure).with(:integrations_group_mention_execution).and_call_original

        expect(groups).to receive_message_chain(:with_integrations,
          :merge).with(Integration.group_mention_hooks).and_return(groups)

        expect(group_1).to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_1).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(group_2).to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_2).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(group_3).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_3).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(execute).to be_success
      end
    end
  end

  shared_examples 'confidential_group_mention_hooks' do
    context "when the 'group_mention_access_check' feature flag is disabled" do
      let(:groups) { all_groups }
      let(:group_mention_access_check_ff_enabled) { false }

      specify do
        allow(Gitlab::Metrics).to receive(:measure).and_call_original
        expect(Gitlab::Metrics).to receive(:measure).with(:integrations_group_mention_execution).and_call_original

        expect(groups).not_to receive(:with_integrations)

        expect(group_1).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_1).to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(group_2).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_2).to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(group_3).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_3).to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(execute).to be_success
      end
    end

    context "when the 'group_mention_access_check' feature flag is enabled" do
      let(:groups) { groups_with_integrations }
      let(:group_mention_access_check_ff_enabled) { true }

      specify do
        allow(Gitlab::Metrics).to receive(:measure).and_call_original
        expect(Gitlab::Metrics).to receive(:measure).with(:integrations_group_mention_execution).and_call_original

        expect(groups).to receive_message_chain(:with_integrations,
          :merge).with(Integration.group_confidential_mention_hooks).and_return(groups)

        expect(group_1).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_1).to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(group_2).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_2).to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(group_3).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
        expect(group_3).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

        expect(execute).to be_success
      end
    end
  end

  shared_examples 'no_group_mention_hooks' do
    let(:groups) { groups_with_integrations }
    let(:group_mention_access_check_ff_enabled) { true }

    specify do
      allow(Gitlab::Metrics).to receive(:measure).and_call_original
      expect(Gitlab::Metrics).to receive(:measure).with(:integrations_group_mention_execution).and_call_original

      expect(groups).to receive_message_chain(:with_integrations,
        :merge).with(Integration.group_confidential_mention_hooks).and_return(groups)

      expect(group_1).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(group_1).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

      expect(group_2).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(group_2).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

      expect(group_3).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(group_3).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

      expect(execute).to be_success
    end
  end

  shared_examples 'no_success' do
    specify do
      allow(Gitlab::Metrics).to receive(:measure).and_call_original
      expect(Gitlab::Metrics).to receive(:measure).with(:integrations_group_mention_execution).and_call_original

      expect(group_1).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(group_1).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

      expect(group_2).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(group_2).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

      expect(group_3).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(group_3).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

      expect(execute).not_to be_success
    end
  end

  context 'for issue descriptions' do
    let(:hook_data) { mentionable.to_hook_data(author) }
    let(:is_confidential) { mentionable.confidential? }
    let(:mentionable) do
      create(:issue, confidential: issue_confidential, project: project, author: author,
        description: "@#{group_1.full_path} @#{group_2.full_path} @#{group_3.full_path}")
    end

    context 'in public projects without group access' do
      let(:project) { public_project_without_group }

      context 'in public issues' do
        let(:issue_confidential) { false }

        it_behaves_like 'public_group_mention_hooks'
      end

      context 'in confidential issues' do
        let(:issue_confidential) { true }

        it_behaves_like 'no_group_mention_hooks'
      end
    end

    context 'in public projects with group access' do
      let(:project) { public_project_with_group }

      context 'in public issues' do
        let(:issue_confidential) { false }

        it_behaves_like 'public_group_mention_hooks'
      end

      context 'in confidential issues' do
        let(:issue_confidential) { true }

        it_behaves_like 'confidential_group_mention_hooks'
      end
    end

    context 'in private projects without group access' do
      let(:project) { private_project_without_group }

      context 'in public issues' do
        let(:issue_confidential) { false }

        it_behaves_like 'no_group_mention_hooks'
      end

      context 'in confidential issues' do
        let(:issue_confidential) { true }

        it_behaves_like 'no_group_mention_hooks'
      end
    end

    context 'in private projects with group access' do
      let(:project) { private_project_with_group }

      context 'in public issues' do
        let(:issue_confidential) { false }

        it_behaves_like 'confidential_group_mention_hooks'
      end

      context 'in confidential issues' do
        let(:issue_confidential) { true }

        it_behaves_like 'confidential_group_mention_hooks'
      end
    end
  end

  context 'for merge request descriptions' do
    let(:hook_data) { mentionable.to_hook_data(author) }
    let(:is_confidential) { false }
    let(:mentionable) do
      create(:merge_request, source_project: project, target_project: project, author: author,
        description: "@#{group_1.full_path} @#{group_2.full_path} @#{group_3.full_path}")
    end

    context 'in public projects without group access' do
      let(:project) { public_project_without_group }

      it_behaves_like 'public_group_mention_hooks'
    end

    context 'in public projects with group access' do
      let(:project) { public_project_with_group }

      it_behaves_like 'public_group_mention_hooks'
    end

    context 'in private projects without group access' do
      let(:project) { private_project_without_group }

      it_behaves_like 'no_group_mention_hooks'
    end

    context 'in private projects with group access' do
      let(:project) { private_project_with_group }

      it_behaves_like 'confidential_group_mention_hooks'
    end
  end

  context 'for issue notes' do
    let(:hook_data) { Gitlab::DataBuilder::Note.build(mentionable, mentionable.author, :create) }
    let(:is_confidential) { mentionable.confidential?(include_noteable: true) }
    let(:mentionable) do
      create(:note_on_issue, noteable: issue, confidential: note_confidential, project: project, author: author)
    end

    let(:issue) do
      create(:issue, confidential: issue_confidential, project: project, author: author,
        description: "@#{group_1.full_path} @#{group_2.full_path} @#{group_3.full_path}")
    end

    context 'in public projects without group access' do
      let(:project) { public_project_without_group }

      context 'in public issues' do
        let(:issue_confidential) { false }

        context 'for public notes' do
          let(:note_confidential) { false }

          it_behaves_like 'public_group_mention_hooks'
        end

        context 'for internal notes' do
          let(:note_confidential) { true }

          it_behaves_like 'no_group_mention_hooks'
        end
      end

      context 'in confidential issues' do
        let(:issue_confidential) { true }

        context 'for public notes' do
          let(:note_confidential) { false }

          it_behaves_like 'no_group_mention_hooks'
        end

        context 'for internal notes' do
          let(:note_confidential) { true }

          it_behaves_like 'no_group_mention_hooks'
        end
      end
    end

    context 'in public projects with group access' do
      let(:project) { public_project_with_group }

      context 'in public issues' do
        let(:issue_confidential) { false }

        context 'for public notes' do
          let(:note_confidential) { false }

          it_behaves_like 'public_group_mention_hooks'
        end

        context 'for internal notes' do
          let(:note_confidential) { true }

          it_behaves_like 'confidential_group_mention_hooks'
        end
      end

      context 'in confidential issues' do
        let(:issue_confidential) { true }

        context 'for public notes' do
          let(:note_confidential) { false }

          it_behaves_like 'confidential_group_mention_hooks'
        end

        context 'for internal notes' do
          let(:note_confidential) { true }

          it_behaves_like 'confidential_group_mention_hooks'
        end
      end
    end

    context 'in private projects without group access' do
      let(:project) { private_project_without_group }

      context 'in public issues' do
        let(:issue_confidential) { false }

        context 'for public notes' do
          let(:note_confidential) { false }

          it_behaves_like 'no_group_mention_hooks'
        end

        context 'for internal notes' do
          let(:note_confidential) { true }

          it_behaves_like 'no_group_mention_hooks'
        end
      end

      context 'in confidential issues' do
        let(:issue_confidential) { true }

        context 'for public notes' do
          let(:note_confidential) { false }

          it_behaves_like 'no_group_mention_hooks'
        end

        context 'for internal notes' do
          let(:note_confidential) { true }

          it_behaves_like 'no_group_mention_hooks'
        end
      end
    end

    context 'in private projects with group access' do
      let(:project) { private_project_with_group }

      context 'in public issues' do
        let(:issue_confidential) { false }

        context 'for public notes' do
          let(:note_confidential) { false }

          it_behaves_like 'confidential_group_mention_hooks'
        end

        context 'for internal notes' do
          let(:note_confidential) { true }

          it_behaves_like 'confidential_group_mention_hooks'
        end
      end

      context 'in confidential issues' do
        let(:issue_confidential) { true }

        context 'for public notes' do
          let(:note_confidential) { false }

          it_behaves_like 'confidential_group_mention_hooks'
        end

        context 'for internal notes' do
          let(:note_confidential) { true }

          it_behaves_like 'confidential_group_mention_hooks'

          context 'for groups with a Guest member' do
            let_it_be(:member_guest) { create(:user) }

            before_all do
              group_1.add_guest(member_guest)
              group_2.add_guest(member_guest)
            end

            it_behaves_like 'no_group_mention_hooks'
          end
        end
      end
    end
  end

  context 'when more groups are returned' do
    let(:hook_data) { Gitlab::DataBuilder::Note.build(mentionable, mentionable.author, :create) }
    let(:is_confidential) { mentionable.confidential?(include_noteable: true) }
    let(:project) { public_project_with_group }
    let(:mentionable) do
      create(:note_on_issue, noteable: issue, confidential: false, project: project, author: author)
    end

    let(:issue) do
      create(:issue, confidential: false, project: project, author: author,
        description: "@#{group_1.full_path} @#{group_2.full_path} @#{group_3.full_path}")
    end

    let(:groups) { groups_with_integrations }
    let(:group_mention_access_check_ff_enabled) { true }

    it 'limits which groups are processed' do
      stub_const("#{described_class.name}::GroupMentionCheckAllUsers::GROUP_MENTION_LIMIT", 1)

      expect(groups).to receive_message_chain(:with_integrations,
        :merge).with(Integration.group_mention_hooks).and_return(groups)

      expect(group_1).to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(group_1).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

      expect(group_2).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(group_2).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

      expect(group_3).not_to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(group_3).not_to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)

      expect(execute).to be_success
    end
  end

  context 'for invalid mentionables' do
    let_it_be(:mentionable) { Object.new }
    let_it_be(:hook_data) { {} }
    let_it_be(:is_confidential) { false }

    it_behaves_like 'no_success'

    it 'logs an error' do
      expect(Gitlab::IntegrationsLogger).to receive(:error).with('Mentionable without to_ability_name: Object')

      execute
    end
  end
end
