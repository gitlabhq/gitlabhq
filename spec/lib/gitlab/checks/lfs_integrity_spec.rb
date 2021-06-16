# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::LfsIntegrity do
  include ProjectForksHelper

  let!(:time_left) { 50 }
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:newrev) do
    operations = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      BareRepoOperations.new(repository.path)
    end

    # Create a commit not pointed at by any ref to emulate being in the
    # pre-receive hook so that `--not --all` returns some objects
    operations.commit_tree('8856a329dd38ca86dfb9ce5aa58a16d88cc119bd', "New LFS objects")
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
        let(:newrevs) { [Gitlab::Git::BLANK_SHA] }

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
