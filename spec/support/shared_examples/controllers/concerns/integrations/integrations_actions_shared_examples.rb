# frozen_string_literal: true

RSpec.shared_examples Integrations::Actions do
  let(:integration) do
    create(:datadog_integration,
      integration_attributes.merge(
        api_url: 'http://example.com',
        api_key: 'secret'
      )
    )
  end

  describe 'GET #edit' do
    before do
      get :edit, params: routing_params
    end

    it 'assigns the integration' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(assigns(:integration)).to eq(integration)
    end
  end

  describe 'PUT #update' do
    let(:params) do
      {
        datadog_env: 'env',
        datadog_service: 'service'
      }
    end

    before do
      put :update, params: routing_params.merge(integration: params)
    end

    it 'updates the integration with the provided params and redirects to the form' do
      expect(response).to redirect_to(routing_params.merge(action: :edit))
      expect(integration.reload).to have_attributes(params)
    end

    context 'when sending a password field' do
      let(:params) { super().merge(api_key: 'new') }

      it 'updates the integration with the password and other params' do
        expect(response).to be_redirect
        expect(integration.reload).to have_attributes(params)
      end
    end

    context 'when sending a blank password field' do
      let(:params) { super().merge(api_key: '') }

      it 'ignores the password field and saves the other params' do
        expect(response).to be_redirect
        expect(integration.reload).to have_attributes(params.merge(api_key: 'secret'))
      end
    end
  end
end
