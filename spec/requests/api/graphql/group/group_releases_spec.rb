# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group(fullPath).releases()', feature_category: :release_orchestration do
  include GraphqlHelpers

  include_context 'when releases and group releases shared context'

  let(:resource_type) { :group }
  let(:resource) { group }

  describe "ensures that the correct data is returned based on the project's visibility and the user's access level" do
    context 'when the group is private' do
      let_it_be(:group) { create(:group, :private) }
      let_it_be(:project) { create(:project, :repository, :private, group: group) }
      let_it_be(:release) { create(:release, :with_evidence, project: project) }

      before_all do
        group.add_guest(guest)
        group.add_reporter(reporter)
        group.add_developer(developer)
      end

      context 'when the user is not logged in' do
        let(:current_user) { stranger }

        it_behaves_like 'no access to any release data'
      end

      context 'when the user has Guest permissions' do
        let(:current_user) { guest }

        it_behaves_like 'no access to any repository-related fields'
      end

      context 'when the user has Reporter permissions' do
        let(:current_user) { reporter }

        it_behaves_like 'full access to all repository-related fields'
        it_behaves_like 'no access to editUrl'
      end

      context 'when the user has Developer permissions' do
        let(:current_user) { developer }

        it_behaves_like 'full access to all repository-related fields'
        it_behaves_like 'access to editUrl'
      end
    end

    context 'when the group is public' do
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:project) { create(:project, :repository, :public, group: group) }
      let_it_be(:release) { create(:release, :with_evidence, project: project) }

      before_all do
        group.add_guest(guest)
        group.add_reporter(reporter)
        group.add_developer(developer)
      end

      context 'when the user is not logged in' do
        let(:current_user) { stranger }

        it_behaves_like 'no access to any release data'
      end

      context 'when the user has Guest permissions' do
        let(:current_user) { guest }

        it_behaves_like 'full access to all repository-related fields'
        it_behaves_like 'no access to editUrl'
      end

      context 'when the user has Reporter permissions' do
        let(:current_user) { reporter }

        it_behaves_like 'full access to all repository-related fields'
        it_behaves_like 'no access to editUrl'
      end

      context 'when the user has Developer permissions' do
        let(:current_user) { developer }

        it_behaves_like 'full access to all repository-related fields'
        it_behaves_like 'access to editUrl'
      end
    end
  end

  describe 'sorting and pagination' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let(:current_user) { developer }

    let(:data_path) { [:group, :releases] }

    before_all do
      group.add_developer(developer)
    end

    def pagination_query(params)
      graphql_query_for(
        :group,
        { full_path: group.full_path },
        query_graphql_field(:releases, params, "#{page_info} nodes { tagName }")
      )
    end

    def pagination_results_data(nodes)
      nodes.pluck('tagName')
    end

    context 'when sorting by released_at' do
      let_it_be(:release5) { create(:release, project: project, tag: 'v5.5.0', released_at: 3.days.from_now) }
      let_it_be(:release1) { create(:release, project: project, tag: 'v5.1.0', released_at: 3.days.ago) }
      let_it_be(:release4) { create(:release, project: project, tag: 'v5.4.0', released_at: 2.days.from_now) }
      let_it_be(:release2) { create(:release, project: project, tag: 'v5.2.0', released_at: 2.days.ago) }
      let_it_be(:release3) { create(:release, project: project, tag: 'v5.3.0', released_at: 1.day.ago) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :RELEASED_AT_ASC }
          let(:first_param) { 2 }
          let(:all_records) { [release1.tag, release2.tag, release3.tag, release4.tag, release5.tag] }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :RELEASED_AT_DESC }
          let(:first_param) { 2 }
          let(:all_records) { [release5.tag, release4.tag, release3.tag, release2.tag, release1.tag] }
        end
      end
    end
  end
end
