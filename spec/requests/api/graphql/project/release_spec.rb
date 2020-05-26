# frozen_string_literal: true

require 'spec_helper'
require 'pp'

describe 'Query.project(fullPath).release(tagName)' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:milestone_1) { create(:milestone, project: project) }
  let_it_be(:milestone_2) { create(:milestone, project: project) }
  let_it_be(:release) { create(:release, project: project, milestones: [milestone_1, milestone_2]) }
  let_it_be(:release_link_1) { create(:release_link, release: release) }
  let_it_be(:release_link_2) { create(:release_link, release: release) }
  let_it_be(:developer) { create(:user) }

  let(:current_user) { developer }

  def query(rq = release_fields)
    graphql_query_for(:project, { fullPath: project.full_path },
      query_graphql_field(:release, { tagName: release.tag }, rq))
  end

  let(:post_query) { post_graphql(query, current_user: current_user) }
  let(:path_prefix) { %w[project release] }

  let(:data) { graphql_data.dig(*path) }

  before do
    project.add_developer(developer)
  end

  describe 'scalar fields' do
    let(:path) { path_prefix }
    let(:release_fields) do
      query_graphql_field(%{
        tagName
        tagPath
        description
        descriptionHtml
        name
        createdAt
        releasedAt
      })
    end

    before do
      post_query
    end

    it 'finds all release data' do
      expect(data).to eq({
        'tagName' => release.tag,
        'tagPath' => project_tag_path(project, release.tag),
        'description' => release.description,
        'descriptionHtml' => release.description_html,
        'name' => release.name,
        'createdAt' => release.created_at.iso8601,
        'releasedAt' => release.released_at.iso8601
      })
    end
  end

  describe 'milestones' do
    let(:path) { path_prefix + %w[milestones nodes] }
    let(:release_fields) do
      query_graphql_field(:milestones, nil, 'nodes { id title }')
    end

    it 'finds all milestones associated to a release' do
      post_query

      expected = release.milestones.map do |milestone|
        { 'id' => global_id_of(milestone), 'title' => milestone.title }
      end

      expect(data).to match_array(expected)
    end
  end

  describe 'author' do
    let(:path) { path_prefix + %w[author] }
    let(:release_fields) do
      query_graphql_field(:author, nil, 'id username')
    end

    it 'finds the author of the release' do
      post_query

      expect(data).to eq({
        'id' => global_id_of(release.author),
        'username' => release.author.username
      })
    end
  end

  describe 'commit' do
    let(:path) { path_prefix + %w[commit] }
    let(:release_fields) do
      query_graphql_field(:commit, nil, 'sha')
    end

    it 'finds the commit associated with the release' do
      post_query

      expect(data).to eq({ 'sha' => release.commit.sha })
    end
  end

  describe 'assets' do
    describe 'assetsCount' do
      let(:path) { path_prefix + %w[assets] }
      let(:release_fields) do
        query_graphql_field(:assets, nil, 'assetsCount')
      end

      it 'returns the number of assets associated to the release' do
        post_query

        expect(data).to eq({ 'assetsCount' => release.sources.size + release.links.size })
      end
    end

    describe 'links' do
      let(:path) { path_prefix + %w[assets links nodes] }
      let(:release_fields) do
        query_graphql_field(:assets, nil,
          query_graphql_field(:links, nil, 'nodes { id name url external }'))
      end

      it 'finds all release links' do
        post_query

        expected = release.links.map do |link|
          {
            'id' => global_id_of(link),
            'name' => link.name,
            'url' => link.url,
            'external' => link.external?
          }
        end

        expect(data).to match_array(expected)
      end
    end

    describe 'sources' do
      let(:path) { path_prefix + %w[assets sources nodes] }
      let(:release_fields) do
        query_graphql_field(:assets, nil,
          query_graphql_field(:sources, nil, 'nodes { format url }'))
      end

      it 'finds all release sources' do
        post_query

        expected = release.sources.map do |source|
          {
            'format' => source.format,
            'url' => source.url
          }
        end

        expect(data).to match_array(expected)
      end
    end
  end
end
