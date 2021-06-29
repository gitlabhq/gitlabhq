# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ErrorTracking do
  let_it_be(:user) { create(:user) }

  let(:setting) { create(:project_error_tracking_setting) }
  let(:project) { setting.project }

  shared_examples 'returns project settings' do
    it 'returns correct project settings' do
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(
        'active' => setting.reload.enabled,
        'project_name' => setting.project_name,
        'sentry_external_url' => setting.sentry_external_url,
        'api_url' => setting.api_url
      )
    end
  end

  shared_examples 'returns 404' do
    it 'returns no project settings' do
      make_request

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message'])
        .to eq('404 Error Tracking Setting Not Found')
    end
  end

  describe "PATCH /projects/:id/error_tracking/settings" do
    let(:params) { { active: false } }

    def make_request
      patch api("/projects/#{project.id}/error_tracking/settings", user), params: params
    end

    context 'when authenticated as maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'patch settings' do
        it_behaves_like 'returns project settings'

        it 'updates enabled flag' do
          expect(setting).to be_enabled

          make_request

          expect(json_response).to include('active' => false)
          expect(setting.reload).not_to be_enabled
        end

        context 'active is invalid' do
          let(:params) { { active: "randomstring" } }

          it 'returns active is invalid if non boolean' do
            make_request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error'])
              .to eq('active is invalid')
          end
        end

        context 'active is empty' do
          let(:params) { { active: '' } }

          it 'returns 400' do
            make_request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error'])
              .to eq('active is empty')
          end
        end
      end

      context 'without a project setting' do
        let(:project) { create(:project) }

        before do
          project.add_maintainer(user)
        end

        context 'patch settings' do
          it_behaves_like 'returns 404'
        end
      end
    end

    context 'when authenticated as reporter' do
      before do
        project.add_reporter(user)
      end

      context 'patch request' do
        it 'returns 403' do
          make_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when authenticated as developer' do
      before do
        project.add_developer(user)
      end

      context 'patch request' do
        it 'returns 403' do
          make_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when authenticated as non-member' do
      context 'patch request' do
        it 'returns 404' do
          make_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      context 'patch request' do
        it 'returns 401 for update request' do
          make_request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end
  end

  describe "GET /projects/:id/error_tracking/settings" do
    def make_request
      get api("/projects/#{project.id}/error_tracking/settings", user)
    end

    context 'when authenticated as maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'get settings' do
        it_behaves_like 'returns project settings'
      end
    end

    context 'without a project setting' do
      let(:project) { create(:project) }

      before do
        project.add_maintainer(user)
      end

      context 'get settings' do
        it_behaves_like 'returns 404'
      end
    end

    context 'when authenticated as reporter' do
      before do
        project.add_reporter(user)
      end

      it 'returns 403' do
        make_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as developer' do
      before do
        project.add_developer(user)
      end

      it 'returns 403' do
        make_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as non-member' do
      it 'returns 404' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it 'returns 401' do
        make_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
