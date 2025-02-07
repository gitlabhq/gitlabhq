# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Pages, feature_category: :pages do
  let_it_be_with_reload(:project) { create(:project, path: 'my.project', pages_https_only: false) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  describe 'DELETE /projects/:id/pages' do
    let(:path) { "/projects/#{project.id}/pages" }

    it_behaves_like 'DELETE request permissions for admin mode' do
      before do
        stub_pages_setting(enabled: true)
      end

      let(:success_status_code) { :no_content }
      let(:failed_status_code) { :not_found }
    end

    context 'when Pages is disabled' do
      before do
        stub_pages_setting(enabled: false)
      end

      it_behaves_like '404 response' do
        let(:request) { delete api(path, admin, admin_mode: true) }
      end
    end

    context 'when Pages is enabled' do
      before do
        stub_pages_setting(enabled: true)
      end

      context 'when Pages are deployed' do
        it 'returns 204' do
          delete api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:no_content)
        end

        it 'removes the pages' do
          delete api(path, admin, admin_mode: true)

          expect(project.reload.pages_deployed?).to be(false)
        end
      end

      context 'when pages are not deployed' do
        it 'returns 204' do
          delete api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'when there is no project' do
        it 'returns 404' do
          id = -1

          delete api("/projects/#{id}/pages", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
