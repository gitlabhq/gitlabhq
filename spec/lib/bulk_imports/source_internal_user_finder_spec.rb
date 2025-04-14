# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::SourceInternalUserFinder, feature_category: :importers do
  let(:url) { 'https://gitlab.example.com' }
  let(:token) { 'token' }
  let(:bulk_import) { create(:bulk_import, :started, configuration: configuration) }
  let(:configuration) { build(:bulk_import_configuration, url: url, access_token: token) }
  let(:client) { instance_double(BulkImports::Clients::Graphql) }
  let(:service) { described_class.new(configuration) }
  let(:cache_key) { format(described_class::GHOST_USER_CACHE_KEY, bulk_import_id: bulk_import.id) }

  before do
    allow(BulkImports::Clients::Graphql).to receive(:new).with(url: url, token: token).and_return(client)
  end

  describe '#fetch_ghost_user' do
    let(:query) do
      <<~GRAPHQL
        {
          users(usernames: ["ghost", "ghost1", "ghost2", "ghost3", "ghost4", "ghost5", "ghost6"], humans: false) {
            nodes {
              id
              username
              type
            }
          }
        }
      GRAPHQL
    end

    let(:users) do
      [
        { 'id' => 'gid://gitlab/User/210', 'username' => 'ghost1', 'type' => 'GHOST' }
      ]
    end

    context 'when ghost user is found' do
      let(:response) { { 'data' => { 'users' => { 'nodes' => users } } } }

      it 'returns the ghost user from the GraphQL response' do
        expect(client).to receive(:execute).with(query: query).and_return(response)

        result = service.fetch_ghost_user

        expect(result).to eq(users[0])
      end
    end

    context 'when no ghost user is found' do
      let(:response) { { 'data' => { 'users' => { 'nodes' => [] } } } }

      it 'returns nil' do
        expect(client).to receive(:execute).with(query: query).and_return(response)

        result = service.fetch_ghost_user

        expect(result).to be_nil
      end
    end

    context 'when nodes is nil' do
      let(:response) { { 'data' => { 'users' => { 'nodes' => nil } } } }

      it 'returns nil' do
        expect(client).to receive(:execute).with(query: query).and_return(response)

        result = service.fetch_ghost_user

        expect(result).to be_nil
      end
    end

    context 'when the response structure is unexpected' do
      let(:response) { { 'data' => {} } }

      it 'returns nil' do
        expect(client).to receive(:execute).with(query: query).and_return(response)

        result = service.fetch_ghost_user

        expect(result).to be_nil
      end
    end

    context 'when API call fails' do
      let(:error) { StandardError.new('API error') }

      let(:response) { { 'data' => { 'users' => { 'nodes' => users } } } }

      it 'retries the API call with exponential backoff' do
        # First attempt fails
        expect(client).to receive(:execute).with(query: query).and_raise(error).ordered
        # Second attempt fails
        expect(service).to receive(:sleep).with(2) # Exponential backoff 2^1
        expect(client).to receive(:execute).with(query: query).and_raise(error).ordered
        # Third attempt succeeds
        expect(service).to receive(:sleep).with(4).ordered # Exponential backoff 2^2
        expect(client).to receive(:execute).with(query: query).and_return(response).ordered

        result = service.fetch_ghost_user

        expect(result).to eq(users[0])
      end

      it 'gives up after MAX_RETRIES attempts' do
        expect(service).to receive(:sleep).exactly(described_class::MAX_RETRIES - 1).times

        expect(client).to receive(:execute).exactly(described_class::MAX_RETRIES).times.with(query: query)
        .and_raise(error)

        allow(Gitlab::ErrorTracking).to receive(:track_exception).once

        result = service.fetch_ghost_user

        expect(result).to be_nil
      end
    end
  end

  describe '#set_ghost_user_id' do
    let(:ghost_user) { { 'id' => 'gid://gitlab/User/210', 'username' => 'ghost', 'type' => 'GHOST' } }

    context 'when ghost user is found' do
      it 'extracts the ID and caches it' do
        expect(service).to receive(:fetch_ghost_user).and_return(ghost_user)
        expect(Gitlab::Cache::Import::Caching).to receive(:write).with(cache_key, '210')

        service.set_ghost_user_id
      end
    end

    context 'when ghost user is not found' do
      it 'returns nil without caching' do
        expect(service).to receive(:fetch_ghost_user).and_return(nil)
        expect(Gitlab::Cache::Import::Caching).not_to receive(:write)

        result = service.set_ghost_user_id

        expect(result).to be_nil
      end
    end

    context 'when an error occurs' do
      let(:error) { StandardError.new('Error setting ghost user ID') }

      it 'tracks the exception and returns nil' do
        expect(service).to receive(:fetch_ghost_user).and_raise(error)
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          error,
          { message: "Failed to set source ghost user ID", bulk_import_id: bulk_import.id }
        )

        result = service.set_ghost_user_id

        expect(result).to be_nil
      end
    end
  end

  describe '#cached_ghost_user_id' do
    it 'returns the cached ghost user ID' do
      expect(Gitlab::Cache::Import::Caching).to receive(:read).with(cache_key).and_return('210')

      expect(service.cached_ghost_user_id).to eq('210')
    end

    it 'returns nil when no cached value exists' do
      expect(Gitlab::Cache::Import::Caching).to receive(:read).with(cache_key).and_return(nil)

      expect(service.cached_ghost_user_id).to be_nil
    end
  end
end
