# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Registering from an invite' do
  let(:com) { true }

  before do
    allow(Gitlab).to receive(:dev_env_or_com?).and_return(com)
  end

  describe 'GET /users/sign_up/invites/new' do
    subject(:request) { get '/users/sign_up/invites/new' }

    context 'when on .com' do
      it 'renders the template with expected text', :aggregate_failures do
        request

        expect(response).to render_template('layouts/simple_registration')
        expect(response).to render_template(:new)
        expect(response.body).to include('Join your team')
      end
    end

    context 'when not on .com' do
      let(:com) { false }

      it 'returns not found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /users/sign_up/invites' do
    subject(:request) do
      post '/users/sign_up/invites',
           params: {
             user: {
               first_name: 'first',
               last_name: 'last',
               username: 'new_username',
               email: 'new@user.com',
               password: 'Any_password'
             }
           }
    end

    context 'when on .com' do
      it 'creates a user' do
        expect { request }.to change(User, :count).by(1)

        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when not on .com' do
      let(:com) { false }

      it 'returns not found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
