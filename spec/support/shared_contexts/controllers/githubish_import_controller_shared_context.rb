# frozen_string_literal: true

RSpec.shared_context 'a GitHub-ish import controller' do
  let(:user) { create(:user) }
  let(:token) { "asdasd12345" }
  let(:access_params) { { github_access_token: token } }

  before do
    sign_in(user)
    allow(controller).to receive(:"#{provider}_import_enabled?").and_return(true)
  end
end
