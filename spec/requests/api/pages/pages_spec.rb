# frozen_string_literal: true

require 'spec_helper'

describe API::Pages do
  let_it_be(:project) { create(:project, path: 'my.project', pages_https_only: false) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    project.mark_pages_as_deployed
  end

  describe 'DELETE /projects/:id/pages' do
    context 'when Pages is disabled' do
      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
      end

      it_behaves_like '404 response' do
        let(:request) { delete api("/projects/#{project.id}/pages", admin)}
      end
    end

    context 'when Pages is enabled' do
      before do
        allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      end

      context 'when Pages are deployed' do
        it 'returns 204' do
          delete api("/projects/#{project.id}/pages", admin)

          expect(response).to have_gitlab_http_status(204)
        end

        it 'removes the pages' do
          expect_any_instance_of(Gitlab::PagesTransfer).to receive(:rename_project).and_return true
          expect(PagesWorker).to receive(:perform_in).with(5.minutes, :remove, project.namespace.full_path, anything)

          delete api("/projects/#{project.id}/pages", admin )

          expect(project.reload.pages_metadatum.deployed?).to be(false)
        end
      end

      context 'when pages are not deployed' do
        before do
          project.mark_pages_as_not_deployed
        end

        it 'returns 204' do
          delete api("/projects/#{project.id}/pages", admin)

          expect(response).to have_gitlab_http_status(204)
        end
      end

      context 'when there is no project' do
        it 'returns 404' do
          id = -1

          delete api("/projects/#{id}/pages", admin)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
