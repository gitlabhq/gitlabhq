# frozen_string_literal: true

RSpec.shared_examples_for Integrations::SlackControllerSettings do
  describe 'GET slack_auth' do
    subject(:get_slack_auth) { get slack_auth_path }

    context 'when valid CSRF token is provided' do
      before do
        allow_next_instance_of(described_class) do |controller|
          allow(controller).to receive(:valid_authenticity_token?).and_return(true)
        end
      end

      it 'calls service and redirects with no alerts if result is successful' do
        expect_next_instance_of(service) do |service_instance|
          expect(service_instance).to receive(:execute).and_return(ServiceResponse.success)
        end

        get_slack_auth

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url)
        expect(flash[:alert]).to be_nil
        expect(session[:slack_install_success]).to be(true)
      end

      it 'calls service and redirects with an alert if there is a service error' do
        expect_next_instance_of(service) do |service_instance|
          expect(service_instance).to receive(:execute).and_return(ServiceResponse.error(message: 'error'))
        end

        get_slack_auth

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url)
        expect(flash[:alert]).to eq('error')
      end

      context 'when user is unauthorized' do
        let_it_be(:user) { create(:user) }

        it 'returns not found response' do
          expect(service).not_to receive(:new)

          get_slack_auth

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when no CSRF token is provided' do
      it 'returns 403' do
        expect(service).not_to receive(:new)

        get_slack_auth

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when there was an OAuth error' do
      it 'redirects with an alert' do
        expect(service).not_to receive(:new)

        get "#{slack_auth_path}?error=access_denied"

        expect(flash[:alert]).to eq('Access request canceled')
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(redirect_url)
      end
    end
  end

  describe 'DELETE destroy' do
    subject(:delete_destroy) { delete destroy_path }

    let!(:integration) { create_integration }

    it 'destroys the record and redirects back to #edit' do
      expect { delete_destroy }.to change { integration.reload.slack_integration }.to(nil)
      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(redirect_url)
    end

    it 'enqueues a worker job' do
      if propagates_on_destroy
        expect(PropagateIntegrationWorker).to receive(:perform_async).with(integration.id)
      else
        expect(PropagateIntegrationWorker).not_to receive(:perform_async)
      end

      delete_destroy
    end

    context 'when user is unauthorized' do
      let_it_be(:user) { create(:user) }

      it 'returns not found response' do
        delete_destroy

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
