# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GroupMentionService, feature_category: :integrations do
  subject(:execute) { described_class.new(mentionable, hook_data: hook_data, is_confidential: is_confidential).execute }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    allow(mentionable).to receive(:referenced_groups).with(user).and_return([group])
  end

  shared_examples 'group_mention_hooks' do
    specify do
      expect(group).to receive(:execute_integrations).with(anything, :group_mention_hooks)
      expect(execute).to be_success
    end
  end

  shared_examples 'group_confidential_mention_hooks' do
    specify do
      expect(group).to receive(:execute_integrations).with(anything, :group_confidential_mention_hooks)
      expect(execute).to be_success
    end
  end

  context 'for issue descriptions' do
    let(:hook_data) { mentionable.to_hook_data(user) }
    let(:is_confidential) { mentionable.confidential? }

    context 'in public projects' do
      let_it_be(:project) { create(:project, :public) }

      context 'in public issues' do
        let(:mentionable) do
          create(:issue, confidential: false, project: project, author: user, description: "@#{group.full_path}")
        end

        it_behaves_like 'group_mention_hooks'
      end

      context 'in confidential issues' do
        let(:mentionable) do
          create(:issue, confidential: true, project: project, author: user, description: "@#{group.full_path}")
        end

        it_behaves_like 'group_confidential_mention_hooks'
      end
    end

    context 'in private projects' do
      let_it_be(:project) { create(:project, :private) }

      context 'in public issues' do
        let(:mentionable) do
          create(:issue, confidential: false, project: project, author: user, description: "@#{group.full_path}")
        end

        it_behaves_like 'group_confidential_mention_hooks'
      end

      context 'in confidential issues' do
        let(:mentionable) do
          create(:issue, confidential: true, project: project, author: user, description: "@#{group.full_path}")
        end

        it_behaves_like 'group_confidential_mention_hooks'
      end
    end
  end

  context 'for merge request descriptions' do
    let(:hook_data) { mentionable.to_hook_data(user) }
    let(:is_confidential) { false }
    let(:mentionable) do
      create(:merge_request, source_project: project, target_project: project, author: user,
        description: "@#{group.full_path}")
    end

    context 'in public projects' do
      let_it_be(:project) { create(:project, :public) }

      it_behaves_like 'group_mention_hooks'
    end

    context 'in private projects' do
      let_it_be(:project) { create(:project, :private) }

      it_behaves_like 'group_confidential_mention_hooks'
    end
  end

  context 'for issue notes' do
    let(:hook_data) { Gitlab::DataBuilder::Note.build(mentionable, mentionable.author, :create) }
    let(:is_confidential) { mentionable.confidential?(include_noteable: true) }

    context 'in public projects' do
      let_it_be(:project) { create(:project, :public) }

      context 'in public issues' do
        let(:issue) do
          create(:issue, confidential: false, project: project, author: user, description: "@#{group.full_path}")
        end

        context 'for public notes' do
          let(:mentionable) { create(:note_on_issue, noteable: issue, project: project, author: user) }

          it_behaves_like 'group_mention_hooks'
        end

        context 'for internal notes' do
          let(:mentionable) { create(:note_on_issue, :confidential, noteable: issue, project: project, author: user) }

          it_behaves_like 'group_confidential_mention_hooks'
        end
      end
    end

    context 'in private projects' do
      let_it_be(:project) { create(:project, :private) }

      context 'in public issues' do
        let(:issue) do
          create(:issue, confidential: false, project: project, author: user, description: "@#{group.full_path}")
        end

        context 'for public notes' do
          let(:mentionable) { create(:note_on_issue, noteable: issue, project: project, author: user) }

          it_behaves_like 'group_confidential_mention_hooks'
        end

        context 'for internal notes' do
          let(:mentionable) { create(:note_on_issue, :confidential, noteable: issue, project: project, author: user) }

          it_behaves_like 'group_confidential_mention_hooks'
        end
      end
    end
  end
end
