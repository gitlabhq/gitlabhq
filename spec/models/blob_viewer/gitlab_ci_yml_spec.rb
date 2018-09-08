require 'spec_helper'

describe BlobViewer::GitlabCiYml do
  include FakeBlobHelpers
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:data) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }
  let(:blob) { fake_blob(path: '.gitlab-ci.yml', data: data) }
  let(:sha) { sample_commit.id }
  subject { described_class.new(blob) }

  describe '#validation_message' do
    it 'calls prepare! on the viewer' do
      expect(subject).to receive(:prepare!)

      subject.validation_message(project, sha)
    end

    context 'when the configuration is valid' do
      it 'returns nil' do
        expect(subject.validation_message(project, sha)).to be_nil
      end
    end

    context 'when the configuration is invalid' do
      let(:data) { 'oof' }

      it 'returns the error message' do
        expect(subject.validation_message(project, sha)).to eq('Invalid configuration format')
      end
    end
  end
end
