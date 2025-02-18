# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Navigation, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  let(:project_double) { instance_double(Project) }
  let(:group_double) { instance_double(Group) }
  let(:group) { nil }
  let(:options) { {} }
  let(:search_navigation) { described_class.new(user: user, project: project, group: group, options: options) }

  describe '#tab_enabled_for_project?' do
    let(:project) { project_double }
    let(:tab) { :blobs }

    subject(:tab_enabled_for_project) { search_navigation.tab_enabled_for_project?(tab) }

    context 'when user has ability for tab' do
      before do
        allow(search_navigation).to receive(:can?).with(user, :read_code, project_double).and_return(true)
      end

      it { is_expected.to be(true) }
    end

    context 'when user does not have ability for tab' do
      before do
        allow(search_navigation).to receive(:can?).with(user, :read_code, project_double).and_return(false)
      end

      it { is_expected.to be(false) }
    end

    context 'when an array of projects is provided' do
      let(:project) { Array.wrap(project_double) }

      before do
        allow(search_navigation).to receive(:can?).with(user, :read_code, project_double).and_return(true)
      end

      it { is_expected.to be(true) }
    end

    context 'when project is not present' do
      let_it_be(:project) { nil }

      it { is_expected.to be(false) }
    end
  end

  describe '#tabs' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(search_navigation).to receive_messages(can?: true, tab_enabled_for_project?: false)
      allow(search_navigation).to receive(:tab_enabled_for_project?).and_call_original
    end

    subject(:tabs) { search_navigation.tabs }

    context 'for projects tab' do
      where(:project, :condition) do
        nil | true
        ref(:project_double) | false
      end

      with_them do
        it 'data item condition is set correctly' do
          expect(tabs[:projects][:condition]).to eq(condition)
        end
      end
    end

    context 'for code tab' do
      where(:project, :group, :tab_enabled_for_project, :condition) do
        nil | nil | false | false
        nil | ref(:group_double) | false | false
        ref(:project_double) | nil | true  | true
        ref(:project_double) | nil | false | false
      end

      with_them do
        let(:options) { {} }

        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:tab_enabled_for_project?)
            .with(:blobs).and_return(tab_enabled_for_project)

          expect(tabs[:blobs][:condition]).to eq(condition)
        end
      end
    end

    context 'for issues tab' do
      where(:tab_enabled, :setting_enabled, :project, :condition) do
        false | false | nil | false
        false | true | nil | true
        false | true | ref(:project_double) | false
        false | false | ref(:project_double) | false
        true | false | nil | true
        true | true | nil | true
        true | false | ref(:project_double) | true
        true | true | ref(:project_double) | true
      end

      with_them do
        before do
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:issues).and_return(tab_enabled)
          stub_application_setting(global_search_issues_enabled: setting_enabled)
        end

        it 'data item condition is set correctly' do
          expect(tabs[:issues][:condition]).to eq(condition)
        end
      end
    end

    context 'for merge requests tab' do
      where(:tab_enabled, :setting_enabled, :project, :condition) do
        false | false | nil | false
        true | false | nil | true
        false | false | ref(:project_double) | false
        true | false | ref(:project_double) | true
        false | true | nil | true
        true | true | nil | true
        false | true | ref(:project_double) | false
        true | true | ref(:project_double) | true
      end

      with_them do
        before do
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:merge_requests).and_return(tab_enabled)
          stub_application_setting(global_search_merge_requests_enabled: setting_enabled)
        end

        it 'data item condition is set correctly' do
          expect(tabs[:merge_requests][:condition]).to eq(condition)
        end
      end
    end

    context 'for wiki tab' do
      where(:project, :group, :tab_enabled_for_project, :condition) do
        nil | nil | false | false
        nil | ref(:group_double) | false | false
        ref(:project_double) | nil | true | true
        ref(:project_double) | nil | false | false
      end

      with_them do
        let(:options) { {} }

        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:tab_enabled_for_project?)
            .with(:wiki_blobs).and_return(tab_enabled_for_project)

          expect(tabs[:wiki_blobs][:condition]).to eq(condition)
        end
      end
    end

    context 'for commits tab' do
      where(:project, :ability_enabled, :condition) do
        nil                  | true  | false
        nil                  | false | false
        ref(:project_double) | true  | true
        ref(:project_double) | false | false
      end

      with_them do
        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:can?).with(user, :read_code, project).and_return(ability_enabled)

          expect(tabs[:commits][:condition]).to eq(condition)
        end
      end
    end

    context 'for comments tab' do
      where(:tab_enabled, :show_elasticsearch_tabs, :project, :condition) do
        true | true | nil | true
        true | true | ref(:project_double) | true
        false | false | nil | false
        false | false | ref(:project_double) | false
        false | true | nil | true
        false | true | ref(:project_double) | false
        true | false | nil | true
        true | false | ref(:project_double) | true
      end

      with_them do
        let(:options) { { show_elasticsearch_tabs: show_elasticsearch_tabs } }

        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:notes).and_return(tab_enabled)

          expect(tabs[:notes][:condition]).to eq(condition)
        end
      end
    end

    context 'for milestones tab' do
      where(:project, :tab_enabled, :condition) do
        ref(:project_double) | true | true
        nil | false | true
        ref(:project_double) | false | false
        nil | true | true
      end

      with_them do
        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:milestones).and_return(tab_enabled)

          expect(tabs[:milestones][:condition]).to eq(condition)
        end
      end
    end

    context 'for users tab' do
      where(:setting_enabled, :can_read_users_list, :project, :tab_enabled, :condition) do
        false | false | ref(:project_double) | true | true
        false | false | nil | false | false
        false | true | nil | false | false
        false | true | ref(:project_double) | false | false
        true | true | nil | false | true
        true | true | ref(:project_double) | false | false
      end

      with_them do
        before do
          stub_application_setting(global_search_users_enabled: setting_enabled)
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:users).and_return(tab_enabled)
          allow(search_navigation).to receive(:can?)
            .with(user, :read_users_list, project_double).and_return(can_read_users_list)
        end

        it 'data item condition is set correctly' do
          expect(tabs[:users][:condition]).to eq(condition)
        end
      end
    end

    context 'for snippet_titles tab' do
      where(:project, :show_snippets, :setting_enabled, :condition) do
        ref(:project_double) | true | false | false
        nil | false | false | false
        ref(:project_double) | false | false | false
        nil | true | false | false
        ref(:project_double) | true | true | false
        nil | false | true | false
        ref(:project_double) | false | true | false
        nil | true | true | true
      end

      with_them do
        let(:options) { { show_snippets: show_snippets } }

        before do
          stub_application_setting(global_search_snippet_titles_enabled: setting_enabled)
        end

        it 'data item condition is set correctly' do
          expect(tabs[:snippet_titles][:condition]).to eq(condition)
        end
      end
    end
  end
end
