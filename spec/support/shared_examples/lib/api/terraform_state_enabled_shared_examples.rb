# frozen_string_literal: true

RSpec.shared_examples 'it depends on value of the `terraform_state.enabled` config' do |params = {}|
  let(:expected_success_status) { params[:success_status] || :ok }

  context 'when terraform_state.enabled=false' do
    before do
      stub_config(terraform_state: { enabled: false })
    end

    it 'returns `forbidden` response' do
      request

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when terraform_state.enabled=true' do
    before do
      stub_config(terraform_state: { enabled: true })
    end

    it 'returns a successful response' do
      request

      expect(response).to have_gitlab_http_status(expected_success_status)
    end
  end
end
