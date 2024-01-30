# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ChangedBlobs, feature_category: :source_code_management do
  let(:repository) { project.repository }

  subject(:service) do
    described_class.new(project, revisions, bytes_limit: 100).execute(timeout: 60)
  end

  describe '#execute' do
    context 'without quarantine directory' do
      let_it_be(:project) { create(:project, :repository) }

      let(:revisions) { ['e774ebd33ca5de8e6ef1e633fd887bb52b9d0a7a'] }

      it 'returns the blobs' do
        project.repository.delete_branch('add-pdf-file')

        expect(repository).to receive(:list_blobs).and_call_original

        expect(service).to contain_exactly(kind_of(Gitlab::Git::Blob))
      end
    end

    context 'with quarantine directory' do
      let_it_be(:project) { create(:project, :small_repo) }

      let(:revisions) { [repository.commit.id] }

      let(:git_env) do
        {
          'GIT_OBJECT_DIRECTORY_RELATIVE' => "objects",
          'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => ['/dir/one', '/dir/two']
        }
      end

      before do
        allow(Gitlab::Git::HookEnv).to receive(:all).with(repository.gl_repository).and_return(git_env)
      end

      context 'when the blob does not exist in the repo' do
        before do
          allow(repository.gitaly_commit_client).to receive(:object_existence_map).and_return(Hash.new { false })
        end

        it 'returns the blobs' do
          expect(service.size).to eq(1)
          expect(service.first).to be_kind_of(Gitlab::Git::Blob)
        end
      end

      context 'when the blob exists in the repo' do
        before do
          allow(repository.gitaly_commit_client).to receive(:object_existence_map).and_return(Hash.new { true })
        end

        it 'filters out the blobs' do
          expect(service).to eq([])
        end
      end
    end
  end
end
