# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::NamespaceVisitsController, type: :request, feature_category: :navigation do
  describe "POST /" do
    let_it_be(:path) { track_namespace_visits_path }
    let_it_be(:request_params) { nil }

    subject(:request) { post path, params: request_params }

    context "when user is not signed-in" do
      it 'throws an error 302' do
        subject

        expect(response).to have_gitlab_http_status(:redirect)
      end
    end

    context "when user is signed-in" do
      let_it_be(:user) { create(:user) }
      let(:server_side_frecent_namespaces) { true }

      before do
        stub_feature_flags(server_side_frecent_namespaces: server_side_frecent_namespaces)
        sign_in(user)
      end

      context "when the server_side_frecent_namespaces feature flag is disabled" do
        let(:server_side_frecent_namespaces) { false }

        it 'throws an error 302' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when entity type is not provided" do
        let_it_be(:request_params) { { id: '1' } }

        it 'responds with a code 400' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context "when entity ID is not provided" do
        let_it_be(:request_params) { { type: 'projects' } }

        it 'responds with a code 400' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context "when entity type and ID are provided" do
        let_it_be(:request_params) { { type: 'projects', id: 1 } }

        it 'calls the worker and responds with a code 200' do
          expect(Users::TrackNamespaceVisitsWorker).to receive(:perform_async)

          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
