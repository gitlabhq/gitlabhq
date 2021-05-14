# frozen_string_literal: true

RSpec.shared_examples '#create_or_update action' do
  let(:params) do
    { integration: { application_type: 'prometheus', enabled: true } }
  end

  let(:path) { raise NotImplementedError }
  let(:redirect_path) { raise NotImplementedError }

  describe 'authorization' do
    subject do
      post path, params: params
    end

    it_behaves_like 'a secure endpoint'
  end

  describe 'functionality' do
    before do
      sign_in(user)
    end

    it 'redirects on success' do
      post path, params: params

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(redirect_path)
      expect(flash[:notice]).to be_present
    end

    it 'redirects on error' do
      error = ServiceResponse.error(message: 'failed')

      expect_next_instance_of(Clusters::Integrations::CreateService) do |service|
        expect(service).to receive(:execute).and_return(error)
      end

      post path, params: params

      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(redirect_path)
      expect(flash[:alert]).to eq(error.message)
    end
  end
end
