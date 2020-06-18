# frozen_string_literal: true

require 'spec_helper'

describe 'Query.project(fullPath).releases()' do
  include GraphqlHelpers

  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:stranger) { create(:user) }

  let(:query) do
    graphql_query_for(:project, { fullPath: project.full_path },
    %{
      releases {
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
        }
      }
    })
  end

  let(:post_query) { post_graphql(query, current_user: current_user) }

  let(:data) { graphql_data.dig('project', 'releases', 'nodes', 0) }

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

        expect(data).to eq({
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
          }
        })
      end
    end
  end

  shared_examples 'no access to any repository-related fields' do
    describe 'repository-related fields' do
      before do
        post_query
      end

      it 'does not return data for fields that expose repository information' do
        expect(data).to eq({
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
          }
        })
      end
    end
  end

  describe "ensures that the correct data is returned based on the project's visibility and the user's access level" do
    context 'when the project is private' do
      let_it_be(:project) { create(:project, :repository, :private) }
      let_it_be(:release) { create(:release, :with_evidence, project: project) }

      before_all do
        project.add_guest(guest)
        project.add_reporter(reporter)
      end

      context 'when the user has Guest permissions' do
        let(:current_user) { guest }

        it_behaves_like 'no access to any repository-related fields'
      end

      context 'when the user has Reporter permissions' do
        let(:current_user) { reporter }

        it_behaves_like 'full access to all repository-related fields'
      end
    end

    context 'when the project is public' do
      let_it_be(:project) { create(:project, :repository, :public) }
      let_it_be(:release) { create(:release, :with_evidence, project: project) }

      before_all do
        project.add_guest(guest)
        project.add_reporter(reporter)
      end

      context 'when the user is not logged in' do
        let(:current_user) { stranger }

        it_behaves_like 'full access to all repository-related fields'
      end

      context 'when the user has Guest permissions' do
        let(:current_user) { guest }

        it_behaves_like 'full access to all repository-related fields'
      end
    end
  end
end
