# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Pages, feature_category: :pages do
  let_it_be_with_reload(:project) { create(:project, path: 'my.project', pages_https_only: false) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    project.mark_pages_as_deployed
  end

  describe 'DELETE /projects/:id/pages' do
    let(:path) { "/projects/#{project.id}/pages" }

    it_behaves_like 'DELETE request permissions for admin mode' do
      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      end

      let(:succes_status_code) { :no_content }
    end

    context 'when Pages is disabled' do
      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
      end

      it_behaves_like '404 response' do
        let(:request) { delete api(path, admin, admin_mode: true) }
      end
    end

    context 'when Pages is enabled' do
      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      end

      context 'when Pages are deployed' do
        it 'returns 204' do
          delete api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:no_content)
        end

        it 'removes the pages' do
          delete api(path, admin, admin_mode: true)

          expect(project.reload.pages_metadatum.deployed?).to be(false)
        end
      end

      context 'when pages are not deployed' do
        before do
          project.mark_pages_as_not_deployed
        end

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
