# frozen_string_literal: true

RSpec.shared_examples 'runner migrations backoff' do
  context 'when executing locking database migrations' do
    it 'returns 429 error', :aggregate_failures do
      expect(Gitlab::Database::Migrations::RunnerBackoff::Communicator)
        .to receive(:backoff_runner?)
        .and_return(true)

      request

      expect(response).to have_gitlab_http_status(:too_many_requests)
      expect(response.headers['Retry-After']).to eq(60)
      expect(json_response).to match({ "message" => "Executing database migrations. Please retry later." })
    end

    context 'with runner_migrations_backoff disabled' do
      before do
        stub_feature_flags(runner_migrations_backoff: false)
      end

      it 'does not return 429' do
        expect(Gitlab::ExclusiveLease).not_to receive(:new)
          .with(Gitlab::Database::Migrations::RunnerBackoff::Communicator::KEY,
            timeout: Gitlab::Database::Migrations::RunnerBackoff::Communicator::EXPIRY)

        request

        expect(response).not_to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end
