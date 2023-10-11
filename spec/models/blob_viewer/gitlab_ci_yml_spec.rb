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

    context 'when the sha is from a fork' do
      include_context 'when a project repository contains a forked commit'

      let(:sha) { forked_commit_sha }

      context 'when a project ref contains the sha' do
        before do
          mock_branch_contains_forked_commit_sha
        end

        it 'returns nil' do
          expect(validation_message).to be_nil
        end
      end

      context 'when a project ref does not contain the sha' do
        it 'returns an error' do
          expect(validation_message).to match(
            /configuration originates from an external project or a commit not associated with a Git reference/)
        end
      end
    end
  end
end
