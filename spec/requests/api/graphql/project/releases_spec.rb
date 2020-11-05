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

  describe 'ensures that the release data can be contolled by a feature flag' do
    context 'when the graphql_release_data feature flag is disabled' do
      let_it_be(:project) { create(:project, :repository, :public) }
      let_it_be(:release) { create(:release, project: project) }

      let(:current_user) { developer }

      before do
        stub_feature_flags(graphql_release_data: false)

        project.add_developer(developer)
      end

      it_behaves_like 'no access to any release data'
    end
  end

  describe 'sorting behavior' do
    let_it_be(:today) { Time.now }
    let_it_be(:yesterday) { today - 1.day }
    let_it_be(:tomorrow) { today + 1.day }

    let_it_be(:project) { create(:project, :repository, :public) }

    let_it_be(:release_v1) { create(:release, project: project, tag: 'v1', released_at: yesterday, created_at: tomorrow) }
    let_it_be(:release_v2) { create(:release, project: project, tag: 'v2', released_at: today,     created_at: yesterday) }
    let_it_be(:release_v3) { create(:release, project: project, tag: 'v3', released_at: tomorrow,  created_at: today) }

    let(:current_user) { developer }

    let(:params) { nil }

    let(:sorted_tags) do
      graphql_data.dig('project', 'releases', 'nodes').map { |release| release['tagName'] }
    end

    let(:query) do
      graphql_query_for(:project, { fullPath: project.full_path },
        %{
          releases#{params ? "(#{params})" : ""} {
            nodes {
              tagName
            }
          }
        })
    end

    before do
      post_query
    end

    context 'when no sort: parameter is provided' do
      it 'returns the results with the default sort applied (sort: RELEASED_AT_DESC)' do
        expect(sorted_tags).to eq(%w(v3 v2 v1))
      end
    end

    context 'with sort: RELEASED_AT_DESC' do
      let(:params) { 'sort: RELEASED_AT_DESC' }

      it 'returns the releases ordered by released_at in descending order' do
        expect(sorted_tags).to eq(%w(v3 v2 v1))
      end
    end

    context 'with sort: RELEASED_AT_ASC' do
      let(:params) { 'sort: RELEASED_AT_ASC' }

      it 'returns the releases ordered by released_at in ascending order' do
        expect(sorted_tags).to eq(%w(v1 v2 v3))
      end
    end

    context 'with sort: CREATED_DESC' do
      let(:params) { 'sort: CREATED_DESC' }

      it 'returns the releases ordered by created_at in descending order' do
        expect(sorted_tags).to eq(%w(v1 v3 v2))
      end
    end

    context 'with sort: CREATED_ASC' do
      let(:params) { 'sort: CREATED_ASC' }

      it 'returns the releases ordered by created_at in ascending order' do
        expect(sorted_tags).to eq(%w(v2 v3 v1))
      end
    end
  end
end
