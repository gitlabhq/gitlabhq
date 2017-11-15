require 'spec_helper'

describe BlobViewerEntity do
  let(:ref) { 'master' }
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(ref) }
  let(:blob) { project.repository.blob_at(commit.id, 'README.md') }
  let(:params) do
    {
      namespace_id: project.namespace,
      project_id: project,
      id: "#{ref}/#{blob.path}"
    }
  end
  let(:request) { double('request', ref: ref, commit: commit, project: project, params: params) }
  let(:entity) { described_class.new(blob.rich_viewer, request: request) }

  subject { entity.as_json }

  it do
    expect(subject).to include(:type, :name, :switcher_icon, :switcher_title, :server_side,
      :render_error, :render_error_reason, :path)
  end
end
