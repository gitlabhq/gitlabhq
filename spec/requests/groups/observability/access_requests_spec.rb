# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Groups::Observability::AccessRequests", feature_category: :observability do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :empty_repo, group: group) }

  let(:service_instance) { instance_double(::Observability::AccessRequestService) }

  before_all do
    group.add_developer(user)
    automation_bot = Users::Internal.automation_bot
    project.add_developer(automation_bot)
  end

  before do
    sign_in(user)
  end

  shared_examples 'requires feature flag' do
    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(observability_sass_features: false)
      end

      it 'returns 404' do
        subject
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'requires permissions' do
    context 'without proper permissions' do
      before do
        group.members.find_by(user: user).destroy!
      end

      it 'returns 403' do
        subject
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  shared_examples 'returns 404 when group has observability settings' do
    context 'when group has observability settings' do
      before do
        create(:observability_group_o11y_setting, group: group)
      end

      it 'returns 404' do
        subject
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "GET /new" do
    subject(:get_new_access_request) { get new_group_observability_access_requests_path(group) }

    include_examples 'requires feature flag'
    include_examples 'returns 404 when group has observability settings'

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: group)
      end

      it "returns http success and renders new template" do
        get_new_access_request

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:success)
          expect(response).to render_template(:new)
        end
      end

      include_examples 'requires permissions'
    end
  end

  describe "POST /create" do
    subject(:create_access_request) { post group_observability_access_requests_path(group) }

    before do
      allow(::Observability::AccessRequestService).to receive(:new).and_return(service_instance)
    end

    include_examples 'requires feature flag'
    include_examples 'returns 404 when group has observability settings'

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: group)
      end

      context 'when service succeeds' do
        before do
          allow(service_instance).to receive(:execute)
            .and_return(ServiceResponse.success(payload: { issue: create(:issue) }))
        end

        it 'returns http success and calls service correctly' do
          create_access_request

          aggregate_failures do
            expect(response).to have_gitlab_http_status(:success)
            expect(::Observability::AccessRequestService).to have_received(:new).with(group, user)
            expect(service_instance).to have_received(:execute)
          end
        end
      end

      context 'when service fails' do
        let(:error_message) { 'You are not authorized to request observability access' }

        before do
          allow(service_instance).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
        end

        it 'returns unprocessable entity and sets flash message' do
          create_access_request

          aggregate_failures do
            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(flash.now[:alert]).to eq(error_message)
            expect(response).to render_template(:new)
          end
        end
      end

      include_examples 'requires permissions'
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
  end
end
