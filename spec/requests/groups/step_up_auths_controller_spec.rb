# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::StepUpAuthsController, type: :controller, feature_category: :system_access do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  before do
    sign_in(user)
  end

  describe 'GET #new' do
    render_views false

    subject(:make_request) { get :new, params: { group_id: group.to_param } }

    context 'when user is not authenticated' do
      before do
        sign_out(user)
      end

      it 'returns 404' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is authenticated' do
      it 'returns success' do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when step-up auth already succeeded' do
        before do
          allow(Gitlab::Auth::Oidc::StepUpAuthentication).to receive(:succeeded?).and_return(true)
        end

        it 'redirects with notice' do
          make_request

          expect(response).to redirect_to(group_path(group))
          expect(flash[:notice]).to eq('Step-up authentication already completed')
        end
      end
    end
  end
end
