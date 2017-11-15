require 'spec_helper'

describe BlobEntity do
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
  let(:entity) { described_class.new(blob, request: request) }

  subject { entity.as_json }

  it 'exposes correct elements' do
    expect(subject).to include(:id, :path, :name, :mode, :icon, :url, :extension, :mime_type, :file_type,
      :size, :binary, :simple_viewer, :rich_viewer, :auxiliary_viewer, :stored_externally, :expanded,
      :raw_path, :blame_path, :commits_path, :tree_path, :permalink, :last_commit)
  end

  ['simple', 'rich'].each do |viewer|
    it "includes #{viewer} viewer for rich file" do
      viewer = subject[:"#{viewer}_viewer"]
  
      expect(viewer).to include(:type, :name, :switcher_title, :switcher_icon, :server_side, :render_error,
        :render_error_reason, :path)
    end
  end

  context 'binary file' do
    let(:blob) { project.repository.blob_at(commit.id, 'Gemfile.zip') }

    it do
      expect(subject[:rich_viewer]).to eq(nil)
    end
  end
end
