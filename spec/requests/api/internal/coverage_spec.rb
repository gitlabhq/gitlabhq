# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Coverage, feature_category: :code_testing do
  let(:admin) { create(:admin) }

  before_all do
    ::API::API.mount ::API::Internal::Coverage
  end

  describe '/internal/coverage' do
    let(:path) { "/internal/coverage" }

    context 'when user is not admin' do
      it 'GET returns 401' do
        get api(path)
        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'DELETE returns 401' do
        delete api(path)
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when user is admin' do
      let(:coverage_hash) do
        { "./lib/gitlab/database/load_balancing/load_balancer.rb" =>
           { "first_updated_at" => 1718070708,
             "last_updated_at" => 1718073948,
             "file_hash" => "1d6368d5806dba4d4af79450d0df9b72" } }
      end

      let(:resp) { coverage_hash.keys }

      before do
        stub_const('Coverband', Class.new)
        stub_const('Coverband::RUNTIME_TYPE', :runtime)

        allow(Coverband).to receive_message_chain(:configuration, :store, :clear!).and_return({})
        allow(Coverband).to receive_message_chain(:configuration, :store, :coverage)
          .with(:runtime, skip_hash_check: true)
          .and_return(coverage_hash)
      end

      it 'GET returns 200', :aggregate_failures do
        get api(path.to_s, admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:success)
        expect(json_response).to eq(resp)
      end

      it 'DELETE returns 200' do
        delete api(path.to_s, admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:success)
      end
    end
  end
end
