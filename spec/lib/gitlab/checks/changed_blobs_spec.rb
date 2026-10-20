# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ChangedBlobs, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }

  let(:repository) { project.repository }
  let(:service_params) { {} }

  subject(:blobs) do
    described_class.new(project, revisions, bytes_limit: 100, **service_params).execute(timeout: 60)
  end

  describe '#execute' do
    context 'without quarantine directory' do
      let_it_be(:project) do
        create(:project, :repository).tap do |pr|
          pr.repository.delete_branch('add-pdf-file')
        end
      end

      let(:revisions) { ['e774ebd33ca5de8e6ef1e633fd887bb52b9d0a7a'] }

      it 'returns the blobs' do
        expect(repository).to receive(:list_blobs).with(
          ['--not', '--all', '--not'] + revisions,
          bytes_limit: 100,
          with_paths: false,
          dynamic_timeout: 60
        ).and_call_original

        expect(blobs).to contain_exactly(kind_of(Gitlab::Git::Blob))
        expect(blobs.first.path).to eq('')
      end

      context 'when with_paths option is passed' do
        let(:service_params) { { with_paths: true } }

        it 'populates the paths' do
          expect(repository).to receive(:list_blobs).with(
            ['--not', '--all', '--not'] + revisions,
            bytes_limit: 100,
            with_paths: true,
            dynamic_timeout: 60
          ).and_call_original

          expect(blobs).to contain_exactly(kind_of(Gitlab::Git::Blob))
          expect(blobs.first.path).to eq('files/pdf/test.pdf')
        end
      end
    end

    context 'with quarantine directory', :request_store do
      let_it_be_with_refind(:project) { create(:project, :small_repo) }

      let(:revisions) { [repository.commit.id] }

      before do
        ::Gitlab::Git::HookEnv.set(project.repository.gl_repository,
          project.repository.raw_repository.relative_path,
          'GIT_OBJECT_DIRECTORY_RELATIVE' => 'objects',
          'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => ['/dir/one', '/dir/two'])
      end

      context 'when the blob does not exist in the repo' do
        before do
          allow(repository.gitaly_commit_client).to receive(:object_existence_map).and_return(Hash.new { false })
        end

        it 'returns the blobs' do
          expect(blobs.size).to eq(1)
          expect(blobs.first).to be_kind_of(Gitlab::Git::Blob)
        end

        context 'when the same file with different paths is committed' do
          before_all do
            project.repository.commit_files(
              user,
              branch_name: project.repository.root_ref,
              message: 'Commit to root ref',
              actions: [
                { action: :create, file_path: 'newfile', content: 'New' },
                { action: :create, file_path: 'modified', content: 'Before' }
              ]
            )

            project.repository.commit_files(
              user,
              branch_name: project.repository.root_ref,
              message: 'Another commit to root ref',
              actions: [
                { action: :create, file_path: 'samefile', content: 'New' },
                { action: :update, file_path: 'modified', content: 'After' }
              ]
            )

            project.repository.commits(project.repository.root_ref, limit: 3)
          end

          it 'returns the blobs' do
            expect(blobs.map(&:data)).to contain_exactly(
              'After', 'Before', 'New', 'test'
            )

            expect(blobs.map(&:path)).to all be_blank
          end

          context 'when with_paths option is passed' do
            let(:service_params) { { with_paths: true } }

            it 'populates the paths of the blobs' do
              blobs_data = blobs.map { |blob| [blob.data, blob.path] }

              expect(blobs_data).to contain_exactly(
                %w[After modified],
                %w[Before modified],
                %w[New samefile],
                %w[New newfile],
                ['test', 'test.txt']
              )
            end
          end
        end
      end

      context 'when the blob exists in the repo' do
        before do
          allow(repository.gitaly_commit_client).to receive(:object_existence_map).and_return(Hash.new { true })
        end

        it 'filters out the blobs' do
          expect(blobs).to eq([])
        end
      end
    end
  end
end
