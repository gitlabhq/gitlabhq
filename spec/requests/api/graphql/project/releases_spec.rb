# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).releases()' do
  include GraphqlHelpers

  let_it_be(:stranger) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }

  let(:base_url_params) { { scope: 'all', release_tag: release.tag } }
  let(:opened_url_params) { { state: 'opened', **base_url_params } }
  let(:merged_url_params) { { state: 'merged', **base_url_params } }
  let(:closed_url_params) { { state: 'closed', **base_url_params } }

  let(:query) do
    graphql_query_for(:project, { fullPath: project.full_path },
    %{
      releases {
        count
        nodes {
          tagName
          tagPath
          name
          commit {
            sha
          }
          assets {
            count
            sources {
              nodes {
                url
              }
            }
          }
          evidences {
            nodes {
              sha
            }
          }
          links {
            selfUrl
            openedMergeRequestsUrl
            mergedMergeRequestsUrl
            closedMergeRequestsUrl
            openedIssuesUrl
            closedIssuesUrl
          }
        }
      }
    })
  end

  let(:params_for_issues_and_mrs) { { scope: 'all', state: 'opened', release_tag: release.tag } }
  let(:post_query) { post_graphql(query, current_user: current_user) }

  let(:data) { graphql_data.dig('project', 'releases', 'nodes', 0) }

  before do
    stub_default_url_options(host: 'www.example.com')
  end

  shared_examples 'correct total count' do
    let(:data) { graphql_data.dig('project', 'releases') }

    before do
      create_list(:release, 2, project: project)

      post_query
    end

    it 'returns the total count' do
      expect(data['count']).to eq(project.releases.count)
    end
  end

  shared_examples 'full access to all repository-related fields' do
    describe 'repository-related fields' do
      before do
        post_query
      end

      it 'returns data for fields that are protected in private projects' do
        expected_sources = release.sources.map do |s|
          { 'url' => s.url }
        end

        expected_evidences = release.evidences.map do |e|
          { 'sha' => e.sha }
        end

        expect(data).to eq(
          'tagName' => release.tag,
          'tagPath' => project_tag_path(project, release.tag),
          'name' => release.name,
          'commit' => {
            'sha' => release.commit.sha
          },
          'assets' => {
            'count' => release.assets_count,
            'sources' => {
              'nodes' => expected_sources
            }
          },
          'evidences' => {
            'nodes' => expected_evidences
          },
          'links' => {
            'selfUrl' => project_release_url(project, release),
            'openedMergeRequestsUrl' => project_merge_requests_url(project, opened_url_params),
            'mergedMergeRequestsUrl' => project_merge_requests_url(project, merged_url_params),
            'closedMergeRequestsUrl' => project_merge_requests_url(project, closed_url_params),
            'openedIssuesUrl' => project_issues_url(project, opened_url_params),
            'closedIssuesUrl' => project_issues_url(project, closed_url_params)
          }
        )
      end
    end

    it_behaves_like 'correct total count'
  end

  shared_examples 'no access to any repository-related fields' do
    describe 'repository-related fields' do
      before do
        post_query
      end

      it 'does not return data for fields that expose repository information' do
        expect(data).to eq(
          'tagName' => nil,
          'tagPath' => nil,
          'name' => "Release-#{release.id}",
          'commit' => nil,
          'assets' => {
            'count' => release.assets_count(except: [:sources]),
            'sources' => {
              'nodes' => []
            }
          },
          'evidences' => {
            'nodes' => []
          },
          'links' => nil
        )
      end
    end

    it_behaves_like 'correct total count'
  end

  # editUrl is tested separately becuase its permissions
  # are slightly different than other release fields
  shared_examples 'access to editUrl' do
    let(:query) do
      graphql_query_for(:project, { fullPath: project.full_path },
        %{
          releases {
            nodes {
              links {
                editUrl
              }
            }
          }
        })
    end

    before do
      post_query
    end

    it 'returns editUrl' do
      expect(data).to eq(
        'links' => {
          'editUrl' => edit_project_release_url(project, release)
        }
      )
    end
  end

  shared_examples 'no access to editUrl' do
    let(:query) do
      graphql_query_for(:project, { fullPath: project.full_path },
        %{
          releases {
            nodes {
              links {
                editUrl
              }
            }
          }
        })
    end

    before do
      post_query
    end

    it 'does not return editUrl' do
      expect(data).to eq(
        'links' => {
          'editUrl' => nil
        }
      )
    end
  end

  shared_examples 'no access to any release data' do
    before do
      post_query
    end

    it 'returns nil' do
      expect(data).to eq(nil)
    end
  end

  describe "ensures that the correct data is returned based on the project's visibility and the user's access level" do
    context 'when the project is private' do
      let_it_be(:project) { create(:project, :repository, :private) }
      let_it_be(:release) { create(:release, :with_evidence, project: project) }

      before_all do
        project.add_guest(guest)
        project.add_reporter(reporter)
        project.add_developer(developer)
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

    context 'when the project is public' do
      let_it_be(:project) { create(:project, :repository, :public) }
      let_it_be(:release) { create(:release, :with_evidence, project: project) }

      before_all do
        project.add_guest(guest)
        project.add_reporter(reporter)
        project.add_developer(developer)
      end

      context 'when the user is not logged in' do
        let(:current_user) { stranger }

        it_behaves_like 'full access to all repository-related fields'
        it_behaves_like 'no access to editUrl'
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
    let_it_be(:sort_project) { create(:project, :public) }

    let(:data_path)          { [:project, :releases] }
    let(:current_user)       { developer }

    def pagination_query(params)
      graphql_query_for(
        :project,
        { full_path: sort_project.full_path },
        query_graphql_field(:releases, params, "#{page_info} nodes { tagName }")
      )
    end

    def pagination_results_data(nodes)
      nodes.map { |release| release['tagName'] }
    end

    context 'when sorting by released_at' do
      let_it_be(:release5) { create(:release, project: sort_project, tag: 'v5.5.0', released_at: 3.days.from_now) }
      let_it_be(:release1) { create(:release, project: sort_project, tag: 'v5.1.0', released_at: 3.days.ago) }
      let_it_be(:release4) { create(:release, project: sort_project, tag: 'v5.4.0', released_at: 2.days.from_now) }
      let_it_be(:release2) { create(:release, project: sort_project, tag: 'v5.2.0', released_at: 2.days.ago) }
      let_it_be(:release3) { create(:release, project: sort_project, tag: 'v5.3.0', released_at: 1.day.ago) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { :RELEASED_AT_ASC }
          let(:first_param)      { 2 }
          let(:expected_results) { [release1.tag, release2.tag, release3.tag, release4.tag, release5.tag] }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { :RELEASED_AT_DESC }
          let(:first_param)      { 2 }
          let(:expected_results) { [release5.tag, release4.tag, release3.tag, release2.tag, release1.tag] }
        end
      end
    end

    context 'when sorting by created_at' do
      let_it_be(:release5) { create(:release, project: sort_project, tag: 'v5.5.0', created_at: 3.days.from_now) }
      let_it_be(:release1) { create(:release, project: sort_project, tag: 'v5.1.0', created_at: 3.days.ago) }
      let_it_be(:release4) { create(:release, project: sort_project, tag: 'v5.4.0', created_at: 2.days.from_now) }
      let_it_be(:release2) { create(:release, project: sort_project, tag: 'v5.2.0', created_at: 2.days.ago) }
      let_it_be(:release3) { create(:release, project: sort_project, tag: 'v5.3.0', created_at: 1.day.ago) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { :CREATED_ASC }
          let(:first_param)      { 2 }
          let(:expected_results) { [release1.tag, release2.tag, release3.tag, release4.tag, release5.tag] }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)       { :CREATED_DESC }
          let(:first_param)      { 2 }
          let(:expected_results) { [release5.tag, release4.tag, release3.tag, release2.tag, release1.tag] }
        end
      end
    end
  end
end
