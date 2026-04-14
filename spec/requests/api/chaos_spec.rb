# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Chaos, feature_category: :feature_flags do
  let_it_be(:authorized_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe 'GET /chaos/test' do
    let(:path) { '/chaos/test' }

    before do
      allow(Project).to receive(:count).and_return(1)
      allow(Project).to receive(:offset).with(anything).and_return(Project.where(id: project.id))
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        get api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as a user without access' do
      before do
        stub_feature_flags(ebonet_chaos_endpoint_access: false)
      end

      it 'returns 403' do
        get api(path, other_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as the authorized user' do
      before do
        stub_feature_flags(ebonet_chaos_endpoint_access: authorized_user)
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(ebonet_chaos_tests: false)
        end

        it 'returns 200 ok' do
          get api(path, authorized_user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq({ 'status' => 'ok' })
        end
      end

      context 'when the feature flag is enabled' do
        before do
          stub_feature_flags(ebonet_chaos_tests: project)
        end

        context 'when rand triggers a failure (roll < 0.2)' do
          before do
            allow(Kernel).to receive(:rand).and_return(0.1)
          end

          it 'returns 500' do
            get api(path, authorized_user)

            expect(response).to have_gitlab_http_status(:internal_server_error)
          end
        end

        context 'when rand triggers a delay (0.2 <= roll < 0.4)' do
          before do
            allow(Kernel).to receive(:rand).and_return(0.3)
            allow(Kernel).to receive(:sleep)
          end

          it 'sleeps for 300ms and returns 200 ok' do
            get api(path, authorized_user)

            expect(Kernel).to have_received(:sleep).with(0.3)
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq({ 'status' => 'ok' })
          end
        end

        context 'when rand produces no chaos (roll >= 0.4)' do
          before do
            allow(Kernel).to receive(:rand).and_return(0.5)
          end

          it 'returns 200 ok' do
            get api(path, authorized_user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq({ 'status' => 'ok' })
          end
        end
      end
    end
  end
end
