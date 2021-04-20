# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::GitlabCiYml do
  include FakeBlobHelpers
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:data) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }
  let(:blob) { fake_blob(path: '.gitlab-ci.yml', data: data) }
  let(:sha) { sample_commit.id }

  subject { described_class.new(blob) }

  describe '#validation_message' do
    it 'calls prepare! on the viewer' do
      expect(subject).to receive(:prepare!)

      subject.validation_message(project: project, sha: sha, user: user)
    end

    context 'when the configuration is valid' do
      it 'returns nil' do
        expect(subject.validation_message(project: project, sha: sha, user: user)).to be_nil
      end
    end

    context 'when the configuration is invalid' do
      let(:data) { 'oof' }

      it 'returns the error message' do
        expect(subject.validation_message(project: project, sha: sha, user: user)).to eq('Invalid configuration format')
      end
    end
  end
end
