# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::LfsIntegrity, feature_category: :source_code_management do
  include ProjectForksHelper

  let!(:time_left) { 50 }
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:newrev) do
    newrev = repository.commit_files(
      project.creator,
      branch_name: 'lfs_integrity_spec',
      message: 'New LFS objects',
      actions: [{
        action: :create,
        file_path: 'files/lfs/some.iso',
        content: <<~LFS
        version https://git-lfs.github.com/spec/v1
        oid sha256:91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897
        size 1575078
        LFS
      }]
    )

    # Create a commit not pointed at by any ref to emulate being in the
    # pre-receive hook so that `--not --all` returns some objects
    repository.delete_branch('lfs_integrity_spec')

    newrev
  end

  let(:newrevs) { [newrev] }

  subject { described_class.new(project, newrevs, time_left) }

  describe '#objects_missing?' do
    let(:blob_object) { repository.blob_at_branch('lfs', 'files/lfs/lfs_object.iso') }

    context 'with LFS not enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(false)
      end

      it 'skips integrity check' do
        expect_any_instance_of(Gitlab::Git::LfsChanges).not_to receive(:new_pointers)

        subject.objects_missing?
      end
    end

    context 'with LFS enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      context 'nil rev' do
        let(:newrevs) { [nil] }

        it 'skips integrity check' do
          expect_any_instance_of(Gitlab::Git::LfsChanges).not_to receive(:new_pointers)

          expect(subject.objects_missing?).to be_falsey
        end
      end

      context 'deletion' do
        let(:newrevs) { [Gitlab::Git::SHA1_BLANK_SHA] }

        it 'skips integrity check' do
          expect_any_instance_of(Gitlab::Git::LfsChanges).not_to receive(:new_pointers)

          expect(subject.objects_missing?).to be_falsey
        end
      end

      context 'no changes' do
        let(:newrevs) { [] }

        it 'skips integrity check' do
          expect_any_instance_of(Gitlab::Git::LfsChanges).not_to receive(:new_pointers)

          expect(subject.objects_missing?).to be_falsey
        end
      end

      it 'is true if any LFS blobs are missing' do
        expect(subject.objects_missing?).to be_truthy
      end

      it 'is false if LFS objects have already been uploaded' do
        lfs_object = create(:lfs_object, oid: blob_object.lfs_oid)
        create(:lfs_objects_project, project: project, lfs_object: lfs_object)

        expect(subject.objects_missing?).to be_falsey
      end
    end
  end
end
