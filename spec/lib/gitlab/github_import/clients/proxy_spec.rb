# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Clients::Proxy, :manage, feature_category: :importers do
  subject(:client) { described_class.new(access_token) }

  let(:access_token) { 'test_token' }

  it { expect(client).to delegate_method(:each_object).to(:client) }
  it { expect(client).to delegate_method(:user).to(:client) }
  it { expect(client).to delegate_method(:octokit).to(:client) }

  describe '#repos' do
    let(:search_text) { 'search text' }
    let(:pagination_options) { { limit: 10 } }
    let(:client_stub) { instance_double(Gitlab::GithubImport::Client) }
    let(:client_response) do
      {
        data: {
          search: {
            nodes: [{ name: 'foo' }, { name: 'bar' }],
            pageInfo: { startCursor: 'foo', endCursor: 'bar' },
            repositoryCount: 2
          }
        }
      }
    end

    it 'fetches repos with Gitlab::GithubImport::Client (GraphQL API)' do
      expect(Gitlab::GithubImport::Client)
        .to receive(:new).with(access_token).and_return(client_stub)
      expect(client_stub)
        .to receive(:search_repos_by_name_graphql)
        .with(search_text, pagination_options).and_return(client_response)

      expect(client.repos(search_text, pagination_options)).to eq(
        {
          repos: [{ name: 'foo' }, { name: 'bar' }],
          page_info: { startCursor: 'foo', endCursor: 'bar' },
          count: 2
        }
      )
    end

    context 'when the GraphQL search response contains a nil node' do
      # GithubImport::Client's GraphQL API responses are Sawyer::Resource objects, not plain hashes.
      # A nil mixed into `nodes` breaks Sawyer's own `Resource#to_h`, which only
      # deep-converts an array if every element is a Sawyer::Resource, so `nodes`
      # is left holding raw Sawyer::Resource objects (plus the nil) instead of hashes.
      let(:sawyer_agent) { Sawyer::Agent.new('') }
      let(:client_response) do
        Sawyer::Resource.new(
          sawyer_agent,
          data: {
            search: {
              nodes: [
                { id: 1, name: 'foo', full_name: 'foo/foo' },
                nil,
                { id: 2, name: 'bar', full_name: 'bar/bar' }
              ],
              pageInfo: { startCursor: 'foo', endCursor: 'bar' },
              repositoryCount: 2
            }
          }
        ).to_h
      end

      it 'filters out the nil node and converts the remaining nodes to plain hashes' do
        expect(Gitlab::GithubImport::Client)
          .to receive(:new).with(access_token).and_return(client_stub)
        expect(client_stub)
          .to receive(:search_repos_by_name_graphql)
          .with(search_text, pagination_options).and_return(client_response)

        repos = client.repos(search_text, pagination_options)[:repos]

        expect(repos).to eq(
          [
            { id: 1, name: 'foo', full_name: 'foo/foo' },
            { id: 2, name: 'bar', full_name: 'bar/bar' }
          ]
        )
        expect(repos).to all(be_a(Hash))
      end
    end
  end

  describe '#count_repos_by', :clean_gitlab_redis_shared_state do
    let(:client_stub) { instance_double(Gitlab::GithubImport::Client) }
    let(:client_response) { { data: { search: { repositoryCount: 1 } } } }

    context 'when value is cached' do
      before do
        Gitlab::Cache::Import::Caching.write('github-importer/provider-repo-count/owned/user_id', 3)
      end

      it 'returns repository count from cache' do
        expect(Gitlab::GithubImport::Client)
          .to receive(:new).with(access_token).and_return(client_stub)
        expect(client_stub)
          .not_to receive(:count_repos_by_relation_type_graphql)
          .with({ relation_type: 'owned' })
        expect(client.count_repos_by('owned', 'user_id')).to eq(3)
      end
    end

    context 'when value is not cached' do
      it 'returns repository count' do
        expect(Gitlab::GithubImport::Client)
          .to receive(:new).with(access_token).and_return(client_stub)
        expect(client_stub)
          .to receive(:count_repos_by_relation_type_graphql)
          .with({ relation_type: 'owned' }).and_return(client_response)
        expect(Gitlab::Cache::Import::Caching)
          .to receive(:write)
          .with('github-importer/provider-repo-count/owned/user_id', 1, timeout: 5.minutes)
          .and_call_original
        expect(client.count_repos_by('owned', 'user_id')).to eq(1)
      end
    end
  end
end
