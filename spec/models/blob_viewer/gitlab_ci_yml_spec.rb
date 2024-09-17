# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::GitlabCiYml, feature_category: :source_code_management do
  include FakeBlobHelpers
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:data) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }
  let(:blob) { fake_blob(path: '.gitlab-ci.yml', data: data) }
  let(:sha) { sample_commit.id }

  subject(:blob_viewer) { described_class.new(blob) }

  describe '#validation_message' do
    subject(:validation_message) { blob_viewer.validation_message(project: project, sha: sha, user: user) }

    it 'calls prepare! on the viewer' do
      expect(blob_viewer).to receive(:prepare!)

      validation_message
    end

    it 'calls Gitlab::Ci::Lint#validate with proper parameters' do
      lint = instance_double(
        Gitlab::Ci::Lint, validate: instance_double(Gitlab::Ci::Lint::Result, errors: [])
      )

      expect(Gitlab::Ci::Lint).to receive(:new).with(
        project: project, current_user: user, sha: sha, verify_project_sha: false
      ).and_return(lint)

      validation_message
    end

    context 'when the configuration is valid' do
      it 'returns nil' do
        expect(validation_message).to be_nil
      end
    end

    context 'when the configuration is invalid' do
      let(:data) { 'oof' }

      it 'returns the error message' do
        expect(validation_message).to eq('Invalid configuration format')
      end
    end
  end

  describe '#visible_to?' do
    it 'returns true when the ref is a branch' do
      expect(blob_viewer.visible_to?(user, 'master')).to be_truthy
    end

    it 'returns true when the ref is a tag' do
      expect(blob_viewer.visible_to?(user, 'v1.0.0')).to be_truthy
    end

    it 'returns false when the ref is a commit' do
      expect(blob_viewer.visible_to?(user, sha)).to be_falsey
    end
  end
end
