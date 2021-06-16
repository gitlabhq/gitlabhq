# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LfsObject do
  context 'scopes' do
    describe '.not_existing_in_project' do
      it 'contains only lfs objects not linked to the project' do
        project = create(:project)
        create(:lfs_objects_project, project: project)
        other_lfs_object = create(:lfs_object)

        expect(described_class.not_linked_to_project(project)).to contain_exactly(other_lfs_object)
      end
    end

    describe '.for_oids' do
      it 'returns the correct LfsObjects' do
        lfs_object_1, lfs_object_2 = create_list(:lfs_object, 2)

        expect(described_class.for_oids(lfs_object_1.oid)).to contain_exactly(lfs_object_1)
        expect(described_class.for_oids([lfs_object_1.oid, lfs_object_2.oid])).to contain_exactly(lfs_object_1, lfs_object_2)
      end
    end
  end

  it 'has a distinct has_many :projects relation through lfs_objects_projects' do
    lfs_object = create(:lfs_object)
    project = create(:project)
    [:project, :design].each do |repository_type|
      create(:lfs_objects_project, project: project,
                                   lfs_object: lfs_object,
                                   repository_type: repository_type)
    end

    expect(lfs_object.lfs_objects_projects.size).to eq(2)
    expect(lfs_object.projects.size).to eq(1)
    expect(lfs_object.projects.to_a).to eql([project])
  end

  describe '#local_store?' do
    it 'returns true when file_store is equal to LfsObjectUploader::Store::LOCAL' do
      subject.file_store = LfsObjectUploader::Store::LOCAL

      expect(subject.local_store?).to eq true
    end

    it 'returns false when file_store is equal to LfsObjectUploader::Store::REMOTE' do
      subject.file_store = LfsObjectUploader::Store::REMOTE

      expect(subject.local_store?).to eq false
    end
  end

  describe '#project_allowed_access?' do
    let_it_be(:lfs_object) { create(:lfs_objects_project).lfs_object }
    let_it_be(:project, reload: true) { create(:project) }

    it 'returns true when project is linked' do
      create(:lfs_objects_project, lfs_object: lfs_object, project: project)

      expect(lfs_object.project_allowed_access?(project)).to eq(true)
    end

    it 'returns false when project is not linked' do
      expect(lfs_object.project_allowed_access?(project)).to eq(false)
    end

    context 'when project is a member of a fork network' do
      let_it_be(:fork_network) { create(:fork_network) }
      let_it_be(:fork_network_root_project, reload: true) { fork_network.root_project }
      let_it_be(:fork_network_membership) { create(:fork_network_member, project: project, fork_network: fork_network) }

      it 'returns true for all members when forked project is linked' do
        create(:lfs_objects_project, lfs_object: lfs_object, project: project)

        expect(lfs_object.project_allowed_access?(project)).to eq(true)
        expect(lfs_object.project_allowed_access?(fork_network_root_project)).to eq(true)
      end

      it 'returns true for all members when root of network is linked' do
        create(:lfs_objects_project, lfs_object: lfs_object, project: fork_network_root_project)

        expect(lfs_object.project_allowed_access?(project)).to eq(true)
        expect(lfs_object.project_allowed_access?(fork_network_root_project)).to eq(true)
      end

      it 'returns false when no member of fork network is linked' do
        expect(lfs_object.project_allowed_access?(project)).to eq(false)
        expect(lfs_object.project_allowed_access?(fork_network_root_project)).to eq(false)
      end
    end
  end

  describe '#schedule_background_upload' do
    before do
      stub_lfs_setting(enabled: true)
    end

    subject { create(:lfs_object, :with_file) }

    context 'when object storage is disabled' do
      before do
        stub_lfs_object_storage(enabled: false)
      end

      it 'does not schedule the migration' do
        expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'when object storage is enabled' do
      context 'when background upload is enabled' do
        context 'when is licensed' do
          before do
            stub_lfs_object_storage(background_upload: true)
          end

          it 'schedules the model for migration' do
            expect(ObjectStorage::BackgroundMoveWorker)
              .to receive(:perform_async)
              .with('LfsObjectUploader', described_class.name, :file, kind_of(Numeric))
              .once

            subject
          end

          it 'schedules the model for migration once' do
            expect(ObjectStorage::BackgroundMoveWorker)
              .to receive(:perform_async)
              .with('LfsObjectUploader', described_class.name, :file, kind_of(Numeric))
              .once

            create(:lfs_object, :with_file)
          end
        end
      end

      context 'when background upload is disabled' do
        before do
          stub_lfs_object_storage(background_upload: false)
        end

        it 'schedules the model for migration' do
          expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

          subject
        end
      end
    end

    describe 'file is being stored' do
      subject { create(:lfs_object, :with_file) }

      context 'when existing object has local store' do
        it_behaves_like 'mounted file in local store'
      end

      context 'when direct upload is enabled' do
        before do
          stub_lfs_object_storage(direct_upload: true)
        end

        it_behaves_like 'mounted file in object store'
      end
    end
  end

  describe ".calculate_oid" do
    let(:lfs_object) { create(:lfs_object, :with_file) }

    it 'returns SHA256 sum of the file' do
      path = lfs_object.file.path
      expected = Digest::SHA256.file(path).hexdigest

      expect(described_class.calculate_oid(path)).to eq expected
    end
  end

  context 'when an lfs object is associated with a project' do
    let!(:lfs_object) { create(:lfs_object) }
    let!(:lfs_object_project) { create(:lfs_objects_project, lfs_object: lfs_object) }

    it 'cannot be deleted' do
      expect { lfs_object.destroy! }.to raise_error(ActiveRecord::InvalidForeignKey)

      lfs_object_project.destroy!

      expect { lfs_object.destroy! }.not_to raise_error
    end
  end

  describe '.unreferenced_in_batches' do
    let!(:unreferenced_lfs_object1) { create(:lfs_object, oid: '1') }
    let!(:referenced_lfs_object) { create(:lfs_objects_project).lfs_object }
    let!(:unreferenced_lfs_object2) { create(:lfs_object, oid: '2') }

    it 'returns lfs objects in batches' do
      stub_const('LfsObject::BATCH_SIZE', 1)

      batches = []
      described_class.unreferenced_in_batches { |batch| batches << batch }

      expect(batches.size).to eq(2)
      expect(batches.first).to eq([unreferenced_lfs_object2])
      expect(batches.last).to eq([unreferenced_lfs_object1])
    end
  end
end
