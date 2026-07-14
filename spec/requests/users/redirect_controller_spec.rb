# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Users::RedirectController requests", feature_category: :user_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }

  context 'when user is not logged in' do
    it 'returns 403' do
      get "/-/u/#{user.id}"

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when user is logged in' do
    before do
      sign_in(another_user)
    end

    context 'with valid user id' do
      it 'redirects to user profile page' do
        get "/-/u/#{user.id}"

        expect(response).to redirect_to(user_path(user))
      end
    end

    context 'with invalid user id' do
      it 'returns 404 for non-existent user' do
        get "/-/u/123"

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
