# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GraphsController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository, :private) }
  let(:ref) { 'master' }

  describe 'GET #charts' do
    subject(:send_request) { get charts_project_graph_path(project, ref), params: params }

    let(:params) { {} }

    context 'when user is unauthorized' do
      it 'shows 404' do
        send_request
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is authorized' do
      let(:user) { project.creator }

      before do
        sign_in(user)
      end

      it 'renders content' do
        send_request
        expect(response).to be_successful
      end

      context 'when path includes a space' do
        let(:params) { { path: 'a b' } }

        it 'still renders the page' do
          send_request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
