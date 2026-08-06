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
      # Coverband stores one array slot per source line, nil for non-executable lines
      let(:coverage_hash) do
        { "./lib/gitlab/database/load_balancing/load_balancer.rb" =>
           { "first_updated_at" => 1764105503, "last_updated_at" => 1764105891,
             "file_hash" => "d41d8cd98f00b204e9800998ecf8427e", "data" => [nil, 5, 10, 0, nil] } }
      end

      let(:resp) do
        { "./lib/gitlab/database/load_balancing/load_balancer.rb" => { "2" => 5, "3" => 10, "4" => 0 } }
      end

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
