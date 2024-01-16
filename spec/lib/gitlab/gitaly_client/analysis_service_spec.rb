# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::AnalysisService, feature_category: :gitaly do
  let_it_be(:project) do
    create(:project, :repository)
  end

  let(:repository) { project.repository.raw }
  let(:base) { project.default_branch }
  let(:head) { branch }
  let(:branch) { 'test-check-blobs-generated' }

  let(:client) { described_class.new(repository) }

  describe '#check_blobs_generated' do
    subject(:check_blobs_generated) { client.check_blobs_generated(base, head, changed_paths) }

    before do
      project.repository.create_branch(branch, project.default_branch)

      project.repository.create_file(
        project.creator,
        'file1.txt',
        'new file content',
        message: 'Add new file',
        branch_name: branch)

      project.repository.create_file(
        project.creator,
        'package-lock.json',
        'new file content',
        message: 'Add new file',
        branch_name: branch)

      project.repository.delete_file(
        project.creator,
        'README',
        message: 'Delete README',
        branch_name: branch)
    end

    context 'when valid changed_paths are given' do
      let(:changed_paths) do
        [
          Gitlab::Git::ChangedPath.new(status: :DELETED, path: 'README', old_mode: '100644', new_mode: '0'),
          Gitlab::Git::ChangedPath.new(status: :ADDED, path: 'file1.txt', old_mode: '0', new_mode: '100644'),
          Gitlab::Git::ChangedPath.new(status: :ADDED, path: 'package-lock.json', old_mode: '0', new_mode: '100644')
        ]
      end

      it 'returns an expected array' do
        expect(check_blobs_generated).to contain_exactly(
          { generated: false, path: 'README' },
          { generated: false, path: 'file1.txt' },
          { generated: true, path: 'package-lock.json' }
        )
      end

      context 'when changed_paths includes a submodule' do
        let(:changed_paths) do
          [
            Gitlab::Git::ChangedPath.new(status: :ADDED, path: 'package-lock.json', old_mode: '0', new_mode: '100644'),
            Gitlab::Git::ChangedPath.new(status: :DELETED, path: 'gitlab-shell', old_mode: '160000', new_mode: '0')
          ]
        end

        it 'returns an array wihout the submodule change' do
          expect(check_blobs_generated).to contain_exactly(
            { generated: true, path: 'package-lock.json' }
          )
        end
      end

      context 'when changed_paths only has a submodule' do
        let(:changed_paths) do
          [
            Gitlab::Git::ChangedPath.new(status: :ADDED, path: 'gitlab-shell', old_mode: '0', new_mode: '160000')
          ]
        end

        it 'returns an empty array' do
          expect(check_blobs_generated).to eq([])
        end
      end
    end

    context 'when changed_paths includes a path with :' do
      before do
        project.repository.create_file(
          project.creator,
          'abc:def',
          'new file content',
          message: 'Add new file',
          branch_name: branch)
      end

      let(:changed_paths) do
        [
          Gitlab::Git::ChangedPath.new(status: :ADDED, path: 'abc:def', old_mode: '0', new_mode: '100644')
        ]
      end

      it 'returns an expected array' do
        expect(check_blobs_generated).to contain_exactly(
          { generated: false, path: 'abc:def' }
        )
      end
    end

    context 'when an unknown revision is given' do
      let(:head)  { 'unknownrevision' }
      let(:changed_paths) do
        [
          Gitlab::Git::ChangedPath.new(status: :ADDED, path: 'file1.txt', old_mode: '0', new_mode: '100644')
        ]
      end

      it 'raises an error' do
        expect { check_blobs_generated }.to raise_error(GRPC::Internal)
      end
    end

    context 'when an unknown path is given' do
      let(:changed_paths) do
        [
          Gitlab::Git::ChangedPath.new(status: :ADDED, path: 'unknownpath', old_mode: '0', new_mode: '100644')
        ]
      end

      it 'raises an error' do
        expect { check_blobs_generated }.to raise_error(GRPC::Internal)
      end
    end
  end
end
