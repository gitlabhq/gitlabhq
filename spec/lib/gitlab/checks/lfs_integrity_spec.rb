require 'spec_helper'

describe Gitlab::Checks::LfsIntegrity do
  include ProjectForksHelper
  let(:project) { create(:project, :repository) }
  let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }

  subject { described_class.new(project, newrev) }

  describe '#objects_missing?' do
    let(:blob_object) { project.repository.blob_at_branch('lfs', 'files/lfs/lfs_object.iso') }

    before do
      allow_any_instance_of(Gitlab::Git::RevList).to receive(:new_objects) do |&lazy_block|
        lazy_block.call([blob_object.id])
      end
    end

    context 'with LFS not enabled' do
      it 'skips integrity check' do
        expect_any_instance_of(Gitlab::Git::RevList).not_to receive(:new_objects)

        subject.objects_missing?
      end
    end

    context 'with LFS enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      context 'deletion' do
        let(:newrev) { nil }

        it 'skips integrity check' do
          expect_any_instance_of(Gitlab::Git::RevList).not_to receive(:new_objects)

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

    context 'for forked project' do
      let(:parent_project) { create(:project, :repository) }
      let(:project) { fork_project(parent_project, nil, repository: true) }

      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      it 'is true parent project is missing LFS objects' do
        expect(subject.objects_missing?).to be_truthy
      end

      it 'is false parent project already conatins LFS objects for the fork' do
        lfs_object = create(:lfs_object, oid: blob_object.lfs_oid)
        create(:lfs_objects_project, project: parent_project, lfs_object: lfs_object)

        expect(subject.objects_missing?).to be_falsey
      end
    end
  end
end
