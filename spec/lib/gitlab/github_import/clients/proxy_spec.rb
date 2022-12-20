# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Clients::Proxy, :manage, feature_category: :import do
  subject(:client) { described_class.new(access_token, client_options) }

  let(:access_token) { 'test_token' }
  let(:client_options) { { foo: :bar } }

  describe '#repos' do
    let(:search_text) { 'search text' }
    let(:pagination_options) { { limit: 10 } }

    context 'when remove_legacy_github_client FF is enabled' do
      let(:client_stub) { instance_double(Gitlab::GithubImport::Client) }

      context 'with github_client_fetch_repos_via_graphql FF enabled' do
        let(:client_response) do
          {
            data: {
              search: {
                nodes: [{ name: 'foo' }, { name: 'bar' }],
                pageInfo: { startCursor: 'foo', endCursor: 'bar' }
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
              page_info: { startCursor: 'foo', endCursor: 'bar' }
            }
          )
        end
      end

      context 'with github_client_fetch_repos_via_graphql FF disabled' do
        let(:client_response) do
          { items: [{ name: 'foo' }, { name: 'bar' }] }
        end

        before do
          stub_feature_flags(github_client_fetch_repos_via_graphql: false)
        end

        it 'fetches repos with Gitlab::GithubImport::Client (REST API)' do
          expect(Gitlab::GithubImport::Client)
            .to receive(:new).with(access_token).and_return(client_stub)
          expect(client_stub)
            .to receive(:search_repos_by_name)
            .with(search_text, pagination_options).and_return(client_response)

          expect(client.repos(search_text, pagination_options)).to eq(
            { repos: [{ name: 'foo' }, { name: 'bar' }] }
          )
        end
      end
    end

    context 'when remove_legacy_github_client FF is disabled' do
      let(:client_stub) { instance_double(Gitlab::LegacyGithubImport::Client) }
      let(:search_text) { nil }

      before do
        stub_feature_flags(remove_legacy_github_client: false)
      end

      it 'fetches repos with Gitlab::LegacyGithubImport::Client' do
        expect(Gitlab::LegacyGithubImport::Client)
          .to receive(:new).with(access_token, client_options).and_return(client_stub)
        expect(client_stub).to receive(:repos)
          .and_return([{ name: 'foo' }, { name: 'bar' }])

        expect(client.repos(search_text, pagination_options))
          .to eq({ repos: [{ name: 'foo' }, { name: 'bar' }] })
      end

      context 'with filter params' do
        let(:search_text) { 'fo' }

        it 'fetches repos with Gitlab::LegacyGithubImport::Client' do
          expect(Gitlab::LegacyGithubImport::Client)
            .to receive(:new).with(access_token, client_options).and_return(client_stub)
          expect(client_stub).to receive(:repos)
            .and_return([{ name: 'FOO' }, { name: 'bAr' }])

          expect(client.repos(search_text, pagination_options))
            .to eq({ repos: [{ name: 'FOO' }] })
        end
      end
    end
  end
end
