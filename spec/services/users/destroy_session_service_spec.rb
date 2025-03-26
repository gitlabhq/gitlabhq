# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DestroySessionService, :aggregate_failures, feature_category: :user_management do
  let_it_be(:user_with_session) { create(:user) }
  let(:session_id) { 'session_id' }
  let(:plaintext) { "_gitlab_session=#{session_id}" }
  let(:rack_session) { Rack::Session::SessionId.new(session_id) }
  let(:session_hash) { { 'warden.user.user.key' => [[user_with_session.id], user_with_session.authenticatable_salt] } }

  subject(:execute) do
    described_class.new(current_user: current_user, user: user_with_session,
      private_session_id: rack_session.private_id).execute
  end

  context 'when missing permission' do
    let_it_be(:current_user) { create(:user) }

    it 'returns forbidden' do
      expect(execute).to be_error
      expect(execute.reason).to eq(:forbidden)
    end
  end

  context 'as an admin', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin) }

    context 'with a valid gitlab session in ActiveSession' do
      before do
        allow(ActiveSession).to receive(:sessions_from_ids).with([rack_session.private_id]).and_return([session_hash])
      end

      it 'destroys the session' do
        expect(ActiveSession).to receive(:destroy_session).with(user_with_session, rack_session.private_id)
        expect(execute).to be_success
      end
    end
  end
end
