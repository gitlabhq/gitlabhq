require 'spec_helper'

describe 'projects/blob/_blob.html.haml' do
  include FakeBlobHelpers

  context 'with a signed commit' do
    let(:project) { create(:project, :repository) }
    let(:repository) { project.repository }
    let(:ref) { GpgHelpers::SIGNED_COMMIT_SHA }
    let(:commit) { repository.commit(ref) }
    let(:path) { 'dummy.md' }
    let(:blob) { fake_blob }
    let(:viewer_class) do
      Class.new(BlobViewer::Base) do
        include BlobViewer::ServerSide

        self.collapse_limit = 1.megabyte
        self.size_limit = 5.megabytes
        self.type = :simple
      end
    end
    let(:viewer) { viewer_class.new(blob) }

    before do
      assign(:project, project)
      assign(:repository, repository)
      assign(:commit, commit)
      assign(:last_commit, commit)
      assign(:ref, ref)
      assign(:id, path)
      assign(:path, path)
      assign(:blob, blob)

      controller.params[:controller] = 'projects/blob'
      controller.params[:action] = 'show'
      controller.params[:namespace_id] = project.namespace.to_param
      controller.params[:project_id] = project.to_param
      controller.params[:id] = File.join(ref, blob.path)
    end

    it 'displays GPG status' do
      render partial: 'projects/blob/blob', locals: { blob: blob }
      expect(rendered).to have_css('.gpg-status-box.invalid')
    end
  end
end
