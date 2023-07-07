# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ClientPool, feature_category: :importers do
  subject(:pool) { described_class.new(token_pool: %w[foo bar], per_page: 1, parallel: true) }

  describe '#best_client' do
    it 'returns the client with the most remaining requests' do
      allow(Gitlab::GithubImport::Client).to receive(:new).and_return(
        instance_double(
          Gitlab::GithubImport::Client,
          requests_remaining?: true, remaining_requests: 10, rate_limit_resets_in: 1
        ),
        instance_double(
          Gitlab::GithubImport::Client,
          requests_remaining?: true, remaining_requests: 20, rate_limit_resets_in: 2
        )
      )

      expect(pool.best_client.remaining_requests).to eq(20)
    end

    context 'when all clients are rate limited' do
      it 'returns the client with the closest rate limit reset time' do
        allow(Gitlab::GithubImport::Client).to receive(:new).and_return(
          instance_double(
            Gitlab::GithubImport::Client,
            requests_remaining?: false, remaining_requests: 10, rate_limit_resets_in: 10
          ),
          instance_double(
            Gitlab::GithubImport::Client,
            requests_remaining?: false, remaining_requests: 20, rate_limit_resets_in: 20
          )
        )

        expect(pool.best_client.rate_limit_resets_in).to eq(10)
      end
    end
  end
end
