# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::GitlabSession, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  context 'with a valid gitlab session in ActiveSession' do
    let(:valid_revocable) { user }
    let(:session_id) { 'session_id' }
    let(:plaintext) { "_gitlab_session=#{session_id}" }
    let(:rack_session) { Rack::Session::SessionId.new(session_id) }
    let(:session_hash) { { 'warden.user.user.key' => [[user.id], user.authenticatable_salt] } }

    before do
      allow(ActiveSession).to receive(:sessions_from_ids).with([rack_session.private_id]).and_return([session_hash])
    end

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!', :enable_admin_mode do
      let_it_be(:admin) { create(:admin) }

      it 'deletes the session' do
        expect(ActiveSession).to receive(:destroy_session).with(valid_revocable, rack_session.private_id)
        expect(token.revoke!(admin)).to be_success
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
