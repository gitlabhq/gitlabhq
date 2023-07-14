# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Navigation, feature_category: :global_search do
  let(:user) { instance_double(User) }
  let(:project_double) { instance_double(Project) }
  let(:options) { {} }
  let(:search_navigation) { described_class.new(user: user, project: project, options: options) }

  describe '#tab_enabled_for_project?' do
    let(:project) { project_double }
    let(:tab) { :blobs }

    subject(:tab_enabled_for_project) { search_navigation.tab_enabled_for_project?(tab) }

    context 'when user has ability for tab' do
      before do
        allow(search_navigation).to receive(:can?).with(user, :read_code, project_double).and_return(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when user does not have ability for tab' do
      before do
        allow(search_navigation).to receive(:can?).with(user, :read_code, project_double).and_return(false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when an array of projects is provided' do
      let(:project) { Array.wrap(project_double) }

      before do
        allow(search_navigation).to receive(:can?).with(user, :read_code, project_double).and_return(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when project is not present' do
      let_it_be(:project) { nil }

      it { is_expected.to eq(false) }
    end
  end

  describe '#tabs' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(search_navigation).to receive(:can?).and_return(true)
      allow(search_navigation).to receive(:tab_enabled_for_project?).and_return(false)
      allow(search_navigation).to receive(:feature_flag_tab_enabled?).and_return(false)
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
      where(:feature_flag_enabled, :show_elasticsearch_tabs, :project, :tab_enabled, :condition) do
        false | false | nil | false | false
        true | true | nil | true | true
        true | false | nil | false | false
        false | true | nil | false | false
        false | false | ref(:project_double) | true | true
        true | false | ref(:project_double) | false | false
      end

      with_them do
        let(:options) { { show_elasticsearch_tabs: show_elasticsearch_tabs } }

        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:feature_flag_tab_enabled?)
            .with(:global_search_code_tab).and_return(feature_flag_enabled)
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:blobs).and_return(tab_enabled)

          expect(tabs[:blobs][:condition]).to eq(condition)
        end
      end
    end

    context 'for issues tab' do
      where(:tab_enabled, :feature_flag_enabled, :project, :condition) do
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
        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:feature_flag_tab_enabled?)
            .with(:global_search_issues_tab).and_return(feature_flag_enabled)
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:issues).and_return(tab_enabled)

          expect(tabs[:issues][:condition]).to eq(condition)
        end
      end
    end

    context 'for merge requests tab' do
      where(:tab_enabled, :feature_flag_enabled, :project, :condition) do
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
        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:feature_flag_tab_enabled?)
            .with(:global_search_merge_requests_tab).and_return(feature_flag_enabled)
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:merge_requests).and_return(tab_enabled)

          expect(tabs[:merge_requests][:condition]).to eq(condition)
        end
      end
    end

    context 'for wiki tab' do
      where(:feature_flag_enabled, :show_elasticsearch_tabs, :project, :tab_enabled, :condition) do
        false | false | nil | true | true
        false | false | nil | false | false
        false | false | ref(:project_double) | false | false
        false | true | nil | false | false
        false | true | ref(:project_double) | false | false
        true | false | nil | false | false
        true | true | ref(:project_double) | false | false
      end

      with_them do
        let(:options) { { show_elasticsearch_tabs: show_elasticsearch_tabs } }

        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:feature_flag_tab_enabled?)
            .with(:global_search_wiki_tab).and_return(feature_flag_enabled)
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:wiki_blobs).and_return(tab_enabled)

          expect(tabs[:wiki_blobs][:condition]).to eq(condition)
        end
      end
    end

    context 'for commits tab' do
      where(:feature_flag_enabled, :show_elasticsearch_tabs, :project, :tab_enabled, :condition) do
        false | false | nil | true | true
        false | false | ref(:project_double) | true | true
        false | false | nil | false | false
        false | true | ref(:project_double) | false | false
        false | true | nil | false | false
        true | false | nil | false | false
        true | false | ref(:project_double) | false | false
        true | true | ref(:project_double) | false | false
        true | true | nil | false | true
      end

      with_them do
        let(:options) { { show_elasticsearch_tabs: show_elasticsearch_tabs } }

        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:feature_flag_tab_enabled?)
            .with(:global_search_commits_tab).and_return(feature_flag_enabled)
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:commits).and_return(tab_enabled)

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
      where(:feature_flag_enabled, :can_read_users_list, :project, :tab_enabled, :condition) do
        false | false | ref(:project_double) | true | true
        false | false | nil | false | false
        false | true | nil | false | false
        false | true | ref(:project_double) | false | false
        true | true | nil | false | true
        true | true | ref(:project_double) | false | false
      end

      with_them do
        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:tab_enabled_for_project?).with(:users).and_return(tab_enabled)
          allow(search_navigation).to receive(:can?)
            .with(user, :read_users_list, project_double).and_return(can_read_users_list)
          allow(search_navigation).to receive(:feature_flag_tab_enabled?)
            .with(:global_search_users_tab).and_return(feature_flag_enabled)

          expect(tabs[:users][:condition]).to eq(condition)
        end
      end
    end

    context 'for snippet_titles tab' do
      where(:project, :show_snippets, :feature_flag_enabled, :condition) do
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

        it 'data item condition is set correctly' do
          allow(search_navigation).to receive(:feature_flag_tab_enabled?)
            .with(:global_search_snippet_titles_tab).and_return(feature_flag_enabled)

          expect(tabs[:snippet_titles][:condition]).to eq(condition)
        end
      end
    end
  end
end
