require 'spec_helper'

describe BlobBasicEntity do
  let(:ref) { 'master' }
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(ref) }
  let(:blob) { project.repository.blob_at(commit.id, 'README.md') }
  let(:request) { double('request', ref: ref, commit: commit, project: project) }
  let(:entity) { described_class.new(blob, request: request) }

  subject { entity.as_json }

  it do
    expect(subject).to include(:id, :path, :name, :mode, :icon, :url)
    expect(subject).not_to include(:last_commit)
  end
end
