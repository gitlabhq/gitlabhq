# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ErrorTracking::ProjectSettings, feature_category: :observability do
  let_it_be(:project) { create(:project) }
  let_it_be(:setting) { create(:project_error_tracking_setting, project: project) }
  let_it_be(:project_without_setting) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: [project, project_without_setting]) }
  let_it_be(:maintainer) { create(:user, maintainer_of: [project, project_without_setting]) }
  let_it_be(:non_member) { create(:user) }
  let(:user) { maintainer }

  shared_examples 'returns project settings' do
    it 'returns correct project settings' do
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(
        'active' => setting.reload.enabled,
        'project_name' => setting.project_name,
        'sentry_external_url' => setting.sentry_external_url,
        'api_url' => setting.api_url,
        'integrated' => setting.integrated
      )
    end
  end

  shared_examples 'returns project settings with false for integrated' do
    specify do
      make_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(
        'active' => setting.reload.enabled,
        'project_name' => setting.project_name,
        'sentry_external_url' => setting.sentry_external_url,
        'api_url' => setting.api_url,
        'integrated' => false
      )
    end
  end

  shared_examples 'returns no project settings' do
    it 'returns no project settings' do
      make_request

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message'])
        .to eq('404 Error Tracking Setting Not Found')
    end
  end

  shared_examples 'returns 400' do
    it 'rejects request' do
      make_request

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  shared_examples 'returns 401' do
    it 'rejects request' do
      make_request

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples 'returns 403' do
    it 'rejects request' do
      make_request

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  shared_examples 'returns 404' do
    it 'rejects request' do
      make_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'returns 400 with `integrated` param required or invalid' do |error|
    it 'returns 400' do
      make_request

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error'])
        .to eq(error)
    end
  end

  shared_examples "returns error from UpdateService" do
    it "returns errors" do
      make_request

      expect(json_response['http_status']).to eq('forbidden')
      expect(json_response['message']).to eq('An error occurred')
    end
  end

  describe "PATCH /projects/:id/error_tracking/settings" do
    let(:params) { { active: false, integrated: integrated } }
    let(:integrated) { false }

    def make_request
      patch api("/projects/#{project.id}/error_tracking/settings", user), params: params
    end

    context 'when authenticated as maintainer' do
      context 'with integrated_error_tracking feature enabled' do
        it_behaves_like 'returns project settings'
      end

      context 'with integrated_error_tracking feature disabled' do
        before do
          stub_feature_flags(integrated_error_tracking: false)
        end

        it_behaves_like 'returns project settings with false for integrated'
      end

      it 'updates enabled flag' do
        expect(setting).to be_enabled

        make_request

        expect(json_response).to include('active' => false)
        expect(setting.reload).not_to be_enabled
      end

      context 'when active is invalid' do
        let(:params) { { active: "randomstring" } }

        it 'returns active is invalid if non boolean' do
          make_request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error'])
            .to eq('active is invalid')
        end
      end

      context 'when active is empty' do
        let(:params) { { active: '' } }

        it 'returns 400' do
          make_request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error'])
            .to eq('active is empty')
        end
      end

      context 'with integrated param' do
        let(:params) { { active: true, integrated: true } }

        context 'when integrated_error_tracking feature enabled' do
          before do
            stub_feature_flags(integrated_error_tracking: true)
          end

          it 'updates the integrated flag' do
            expect(setting.integrated).to be_falsey

            make_request

            expect(json_response).to include('integrated' => true)
            expect(setting.reload.integrated).to be_truthy
          end
        end
      end

      context 'without a project setting' do
        let(:project) { project_without_setting }

        it_behaves_like 'returns no project settings'
      end

      context "when ::Projects::Operations::UpdateService responds with an error" do
        before do
          allow_next_instance_of(::Projects::Operations::UpdateService) do |service|
            allow(service)
              .to receive(:execute)
              .and_return({ status: :error, message: 'An error occurred', http_status: :forbidden })
          end
        end

        context "when integrated" do
          let(:integrated) { true }

          it_behaves_like 'returns error from UpdateService'
        end

        context "without integrated" do
          it_behaves_like 'returns error from UpdateService'
        end
      end
    end

    context 'when authenticated as developer' do
      let(:user) { developer }

      it_behaves_like 'returns 403'
    end

    context 'when authenticated as non-member' do
      let(:user) { non_member }

      it_behaves_like 'returns 404'
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it_behaves_like 'returns 401'
    end
  end

  describe "GET /projects/:id/error_tracking/settings" do
    def make_request
      get api("/projects/#{project.id}/error_tracking/settings", user)
    end

    context 'when authenticated as maintainer' do
      it_behaves_like 'returns project settings'

      context 'when integrated_error_tracking feature disabled' do
        before do
          stub_feature_flags(integrated_error_tracking: false)
        end

        it_behaves_like 'returns project settings with false for integrated'
      end
    end

    context 'without a project setting' do
      let(:project) { project_without_setting }

      it_behaves_like 'returns no project settings'
    end

    context 'when authenticated as developer' do
      let(:user) { developer }

      it_behaves_like 'returns 403'
    end

    context 'when authenticated as non-member' do
      let(:user) { non_member }

      it_behaves_like 'returns 404'
    end

    context 'when unauthenticated' do
      let(:user) { nil }

      it_behaves_like 'returns 401'
    end
  end

  describe "PUT /projects/:id/error_tracking/settings" do
    let(:params) { { active: active, integrated: integrated } }
    let(:active) { true }
    let(:integrated) { true }

    def make_request
      put api("/projects/#{project.id}/error_tracking/settings", user), params: params
    end

    context 'when authenticated' do
      context 'as maintainer' do
        context "when integrated" do
          context "with existing setting" do
            let(:active) { false }

            it "updates a setting" do
              expect { make_request }.not_to change { ErrorTracking::ProjectErrorTrackingSetting.count }

              expect(response).to have_gitlab_http_status(:ok)

              expect(json_response).to include("integrated" => true)
            end
          end

          context "without setting" do
            let(:project) { project_without_setting }
            let(:active) { true }

            it "creates a setting" do
              expect { make_request }.to change { ErrorTracking::ProjectErrorTrackingSetting.count }

              expect(response).to have_gitlab_http_status(:ok)

              expect(json_response).to eq(
                "active" => true,
                "api_url" => nil,
                "integrated" => true,
                "project_name" => nil,
                "sentry_external_url" => nil
              )
            end
          end

          context "when ::Projects::Operations::UpdateService responds with an error" do
            before do
              allow_next_instance_of(::Projects::Operations::UpdateService) do |service|
                allow(service)
                  .to receive(:execute)
                        .and_return({ status: :error, message: 'An error occurred', http_status: :forbidden })
              end
            end

            it_behaves_like 'returns error from UpdateService'
          end
        end

        context "when integrated_error_tracking feature disabled" do
          before do
            stub_feature_flags(integrated_error_tracking: false)
          end

          it_behaves_like 'returns 404'
        end

        context "when integrated param is invalid" do
          let(:params) { { active: active, integrated: 'invalid_string' } }

          it_behaves_like 'returns 400 with `integrated` param required or invalid', 'integrated is invalid'
        end

        context "when integrated param is missing" do
          let(:params) { { active: active } }

          it_behaves_like 'returns 400 with `integrated` param required or invalid', 'integrated is missing'
        end
      end

      context "as developer" do
        let(:user) { developer }

        it_behaves_like 'returns 403'
      end

      context 'as non-member' do
        let(:user) { non_member }

        it_behaves_like 'returns 404'
      end
    end

    context "when unauthorized" do
      let(:user) { nil }

      it_behaves_like 'returns 401'
    end
  end
end
