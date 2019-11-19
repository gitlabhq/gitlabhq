# frozen_string_literal: true

require 'spec_helper'

describe LfsObject do
  context 'scopes' do
    describe '.not_existing_in_project' do
      it 'contains only lfs objects not linked to the project' do
        project = create(:project)
        create(:lfs_objects_project, project: project)
        other_lfs_object = create(:lfs_object)

        expect(described_class.not_linked_to_project(project)).to contain_exactly(other_lfs_object)
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
    set(:lfs_object) { create(:lfs_objects_project).lfs_object }
    set(:project) { create(:project) }

    it 'returns true when project is linked' do
      create(:lfs_objects_project, lfs_object: lfs_object, project: project)

      expect(lfs_object.project_allowed_access?(project)).to eq(true)
    end

    it 'returns false when project is not linked' do
      expect(lfs_object.project_allowed_access?(project)).to eq(false)
    end

    context 'when project is a member of a fork network' do
      set(:fork_network) { create(:fork_network) }
      set(:fork_network_root_project) { fork_network.root_project }
      set(:fork_network_membership) { create(:fork_network_member, project: project, fork_network: fork_network) }

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
      let(:lfs_object) { create(:lfs_object, :with_file) }

      context 'when existing object has local store' do
        it 'is stored locally' do
          expect(lfs_object.file_store).to be(ObjectStorage::Store::LOCAL)
          expect(lfs_object.file).to be_file_storage
          expect(lfs_object.file.object_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end

      context 'when direct upload is enabled' do
        before do
          stub_lfs_object_storage(direct_upload: true)
        end

        context 'when file is stored' do
          it 'is stored remotely' do
            expect(lfs_object.file_store).to eq(ObjectStorage::Store::REMOTE)
            expect(lfs_object.file).not_to be_file_storage
            expect(lfs_object.file.object_store).to eq(ObjectStorage::Store::REMOTE)
          end
        end
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
end
