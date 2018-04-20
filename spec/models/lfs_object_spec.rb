require 'spec_helper'

describe LfsObject do
  describe '#local_store?' do
    it 'returns true when file_store is nil' do
      subject.file_store = nil

      expect(subject.local_store?).to eq true
    end

    it 'returns true when file_store is equal to LfsObjectUploader::Store::LOCAL' do
      subject.file_store = LfsObjectUploader::Store::LOCAL

      expect(subject.local_store?).to eq true
    end

    it 'returns false whe file_store is equal to LfsObjectUploader::Store::REMOTE' do
      subject.file_store = LfsObjectUploader::Store::REMOTE

      expect(subject.local_store?).to eq false
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

            lfs_object = create(:lfs_object)
            lfs_object.file = fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "`/png")
            lfs_object.save!
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

      context 'when object has nil store' do
        before do
          lfs_object.update_column(:file_store, nil)
          lfs_object.reload
        end

        it 'is stored locally' do
          expect(lfs_object.file_store).to be(nil)
          expect(lfs_object.file).to be_file_storage
          expect(lfs_object.file.object_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end

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
end
