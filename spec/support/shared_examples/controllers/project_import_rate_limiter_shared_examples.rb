# frozen_string_literal: true

RSpec.shared_examples 'project import rate limiter' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when limit exceeds' do
    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
    end

    it 'notifies and redirects user' do
      post :create, params: {}

      expect(flash[:alert]).to eq('This endpoint has been requested too many times. Try again later.')
      expect(response).to have_gitlab_http_status(:found)
    end
  end
end
