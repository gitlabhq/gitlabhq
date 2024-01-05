# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationController, type: :request, feature_category: :shared do
  let_it_be(:user) { create(:user) }

  it_behaves_like 'Base action controller' do
    before do
      sign_in(user)
    end

    subject(:request) { get root_path }
  end

  describe 'session expiration' do
    context 'when user is authenticated' do
      it 'does not set the expire_after option' do
        sign_in(user)

        get root_path

        expect(request.env['rack.session.options'][:expire_after]).to be_nil
      end
    end

    context 'when user is unauthenticated' do
      it 'sets the expire_after option' do
        get root_path

        expect(request.env['rack.session.options'][:expire_after]).to eq(
          Settings.gitlab['unauthenticated_session_expire_delay']
        )
      end
    end
  end
end
