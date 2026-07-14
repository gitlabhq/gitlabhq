# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Projects::Observability::AccessRequests", feature_category: :observability do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:user_namespace) { user.namespace }
  let_it_be(:project) { create(:project, :empty_repo, namespace: user_namespace) }

  let(:service_instance) { instance_double(::Observability::AccessRequestService) }

  before do
    sign_in(user)
  end

  describe "POST /create" do
    subject(:create_access_request) { post project_observability_access_requests_path(project) }

    before do
      allow(::Observability::AccessRequestService).to receive(:new).and_return(service_instance)
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(observability_sass_features: false)
      end

      it 'returns 404 without calling service' do
        create_access_request

        aggregate_failures do
          expect(::Observability::AccessRequestService).not_to have_received(:new)
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: user_namespace)
      end

      context 'when project belongs to a group' do
        let_it_be(:group) { create(:group) }
        let_it_be(:group_project) { create(:project, :empty_repo, group: group) }

        before_all do
          group.add_developer(user)
        end

        before do
          stub_feature_flags(observability_sass_features: group)
        end

        it 'redirects to the group setup page' do
          post project_observability_access_requests_path(group_project)

          expect(response).to redirect_to(group_observability_setup_path(group))
        end
      end

      context 'when namespace already has observability settings' do
        before do
          create(:observability_group_o11y_setting, group: user_namespace)
        end

        it 'redirects to setup path with alert message' do
          create_access_request
          expect(response).to redirect_to(project_observability_setup_path(project))
          expect(flash[:alert]).to eq('Observability is already enabled for this namespace')
        end
      end

      context 'when service succeeds' do
        before do
          allow(service_instance).to receive(:execute)
            .and_return(ServiceResponse.success(payload: { issue: create(:issue) }))
        end

        it 'redirects to setup path and calls service correctly' do
          create_access_request

          aggregate_failures do
            expect(response).to redirect_to(project_observability_setup_path(project))
            expect(flash[:success]).to include('Observability is enabled for your personal namespace')
            expect(::Observability::AccessRequestService).to have_received(:new)
              .with(user_namespace, user, project: project)
            expect(service_instance).to have_received(:execute)
          end
        end
      end

      context 'when service fails' do
        let(:error_message) { 'You are not authorized to request observability access' }

        before do
          allow(service_instance).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
        end

        it 'redirects to setup path and sets flash message' do
          create_access_request

          aggregate_failures do
            expect(response).to redirect_to(project_observability_setup_path(project))
            expect(flash[:alert]).to eq(error_message)
          end
        end
      end

      context 'without proper permissions' do
        let_it_be(:other_user) { create(:user) }

        before do
          sign_in(other_user)
        end

        it 'returns 404' do
          create_access_request
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
