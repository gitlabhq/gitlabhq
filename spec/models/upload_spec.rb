# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Upload do
  describe 'associations' do
    it { is_expected.to belong_to(:model) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_presence_of(:uploader) }
  end

  describe 'callbacks' do
    context 'for a file above the checksum threshold' do
      it 'schedules checksum calculation' do
        stub_const('UploadChecksumWorker', spy)

        upload = described_class.create!(
          path: __FILE__,
          size: described_class::CHECKSUM_THRESHOLD + 1.kilobyte,
          model: build_stubbed(:user),
          uploader: double('ExampleUploader'),
          store: ObjectStorage::Store::LOCAL
        )

        expect(UploadChecksumWorker)
          .to have_received(:perform_async).with(upload.id)
      end
    end

    context 'for a file at or below the checksum threshold' do
      it 'calculates checksum immediately before save' do
        upload = described_class.new(
          path: __FILE__,
          size: described_class::CHECKSUM_THRESHOLD,
          model: build_stubbed(:user),
          uploader: double('ExampleUploader'),
          store: ObjectStorage::Store::LOCAL
        )

        expect { upload.save! }
          .to change { upload.checksum }.from(nil)
          .to(a_string_matching(/\A\h{64}\z/))
      end
    end

    context 'before_save' do
      it 'sets sharding key on create' do
        project = build_stubbed(:project)
        upload = build(:upload, model: project)

        expect { upload.save! }
          .to change { upload.namespace_id }.from(nil)
          .to(project.uploads_sharding_key.each_value.first)
      end

      it 'sets sharding key on update' do
        project = build_stubbed(:project)
        upload = create(:upload, model: project)
        other_project = build_stubbed(:project)

        expect { upload.update!(model: other_project) }
          .to change { upload.namespace_id }.from(project.uploads_sharding_key.each_value.first)
          .to(other_project.uploads_sharding_key.each_value.first)
      end
    end

    describe 'after_destroy' do
      context 'uploader is FileUploader-based' do
        subject { create(:upload, :issuable_upload) }

        it 'calls delete_file!' do
          is_expected.to receive(:delete_file!)

          subject.destroy!
        end
      end
    end
  end

  describe 'scopes' do
    let_it_be(:project) { create(:project) }

    describe '.for_model_type_and_id' do
      let(:avatar_uploads) { create_list(:upload, 2) }
      let(:attachment_uploads) { create_list(:upload, 2, :attachment_upload) }

      it 'returns records matching the given model_type and ids' do
        model_ids = [avatar_uploads, attachment_uploads].map { |uploads| uploads.first.model_id }

        expect(described_class.for_model_type_and_id(Note, model_ids))
          .to contain_exactly(attachment_uploads.first)
      end
    end

    describe '.for_uploader' do
      let_it_be(:avatar_upload) { create(:upload, model: project) }
      let_it_be(:favicon_upload) { create(:upload, :favicon_upload, model: project) }

      it 'returns uploads matching given uploader class' do
        expect(described_class.for_uploader(AvatarUploader)).to contain_exactly(avatar_upload)
      end

      it 'returns uploads matching given uploader class name' do
        expect(described_class.for_uploader('AvatarUploader')).to contain_exactly(avatar_upload)
      end
    end

    describe '.order_by_created_at_desc' do
      let(:uploads) { create_list(:upload, 3, model: project) }

      it 'returns uploads ordered by created_at descending' do
        expect(described_class.order_by_created_at_desc).to eq(uploads.reverse)
      end
    end
  end

  describe '#absolute_path' do
    it 'returns the path directly when already absolute' do
      path = '/path/to/namespace/project/secret/file.jpg'
      upload = described_class.new(path: path, store: ObjectStorage::Store::LOCAL)

      expect(upload).not_to receive(:uploader_class)

      expect(upload.absolute_path).to eq path
    end

    it "delegates to the uploader's absolute_path method" do
      uploader = spy('FakeUploader')
      upload = described_class.new(path: 'secret/file.jpg', store: ObjectStorage::Store::LOCAL)
      expect(upload).to receive(:uploader_class).and_return(uploader)

      upload.absolute_path

      expect(uploader).to have_received(:absolute_path).with(upload)
    end
  end

  describe '#relative_path' do
    it "delegates to the uploader's relative_path method" do
      uploader = spy('FakeUploader')
      upload = described_class.new(path: '/tmp/secret/file.jpg', store: ObjectStorage::Store::LOCAL)
      expect(upload).to receive(:uploader_class).and_return(uploader)

      upload.relative_path

      expect(uploader).to have_received(:relative_path).with(upload)
    end
  end

  describe '#calculate_checksum!' do
    let(:upload) do
      described_class.new(
        path: __FILE__,
        size: described_class::CHECKSUM_THRESHOLD - 1.megabyte,
        store: ObjectStorage::Store::LOCAL
      )
    end

    it 'sets `checksum` to SHA256 sum of the file' do
      expected = Digest::SHA256.file(__FILE__).hexdigest

      expect { upload.calculate_checksum! }
        .to change { upload.checksum }.from(nil).to(expected)
    end

    it 'sets `checksum` to nil for a non-existent file' do
      expect(upload).to receive(:exist?).and_return(false)

      checksum = Digest::SHA256.file(__FILE__).hexdigest
      upload.checksum = checksum

      expect { upload.calculate_checksum! }
        .to change { upload.checksum }.from(checksum).to(nil)
    end
  end

  describe '#build_uploader' do
    it 'returns a uploader object with current upload associated with it' do
      subject = build(:upload)
      uploader = subject.build_uploader

      expect(uploader.upload).to eq(subject)
      expect(uploader.mounted_as).to eq(subject.send(:mount_point))
      expect(uploader.file).to be_nil
    end
  end

  describe '#retrieve_uploader' do
    it 'returns a uploader object with current uploader associated with and cache retrieved' do
      subject = build(:upload)
      uploader = subject.retrieve_uploader

      expect(uploader.upload).to eq(subject)
      expect(uploader.mounted_as).to eq(subject.send(:mount_point))
      expect(uploader.file).not_to be_nil
    end

    context 'when upload has mount_point nil' do
      context 'when an upload belongs to a note' do
        it 'mounts it as attachment' do
          project = create(:project, :legacy_storage)
          merge_request = create(:merge_request, source_project: project)
          note = create(:legacy_diff_note_on_merge_request, note: 'some note', project: project, noteable: merge_request)

          subject = build(:upload, :with_file, :attachment_upload, model: note, mount_point: nil)
          uploader = subject.retrieve_uploader

          expect(uploader.upload).to eq(subject)
          expect(uploader.path).to include('attachment')
          expect(uploader.file).not_to be_nil
        end
      end

      context 'when an upload does not belong to a note' do
        it 'does not mount it as attachment' do
          appearance = create(:appearance)

          subject = build(:upload, :with_file, :attachment_upload, model: appearance, mount_point: nil)
          uploader = subject.retrieve_uploader

          expect(uploader.upload).to eq(subject)
          expect(uploader.path).not_to include('attachment')
          expect(uploader.file).not_to be_nil
        end
      end
    end
  end

  describe '#needs_checksum?' do
    context 'with local storage' do
      it 'returns true when no checksum exists' do
        subject = create(:upload, :with_file, checksum: nil)

        expect(subject.needs_checksum?).to be_truthy
      end

      it 'returns false when checksum is already present' do
        subject = create(:upload, :with_file, checksum: 'something')

        expect(subject.needs_checksum?).to be_falsey
      end
    end

    context 'with remote storage' do
      subject { build(:upload, :object_storage) }

      it 'returns false' do
        expect(subject.needs_checksum?).to be_falsey
      end
    end
  end

  describe '#exist?' do
    it 'returns true when the file exists' do
      upload = described_class.new(path: __FILE__, store: ObjectStorage::Store::LOCAL)

      expect(upload).to exist
    end

    context 'when the file does not exist' do
      it 'returns false' do
        upload = described_class.new(path: "#{__FILE__}-nope", store: ObjectStorage::Store::LOCAL)

        expect(upload).not_to exist
      end

      context 'when the record is persisted' do
        it 'sends a message to Sentry' do
          upload = create(:upload, :issuable_upload)

          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(RuntimeError), upload.attributes)

          upload.exist?
        end

        it 'increments a metric counter to signal a problem' do
          upload = create(:upload, :issuable_upload)

          counter = double(:counter)
          expect(counter).to receive(:increment)
          expect(Gitlab::Metrics).to receive(:counter).with(:upload_file_does_not_exist_total, 'The number of times an upload record could not find its file').and_return(counter)

          upload.exist?
        end
      end

      context 'when the record is not persisted' do
        it 'does not send a message to Sentry' do
          upload = described_class.new(path: "#{__FILE__}-nope", store: ObjectStorage::Store::LOCAL)

          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          upload.exist?
        end

        it 'does not increment a metric counter' do
          upload = described_class.new(path: "#{__FILE__}-nope", store: ObjectStorage::Store::LOCAL)

          expect(Gitlab::Metrics).not_to receive(:counter)

          upload.exist?
        end
      end
    end
  end

  describe "#uploader_context" do
    subject { create(:upload, :issuable_upload, secret: 'secret', filename: 'file.txt') }

    it { expect(subject.uploader_context).to match(a_hash_including(secret: 'secret', identifier: 'file.txt')) }
  end

  describe '#update_project_statistics' do
    let_it_be(:project) { create(:project) }

    subject do
      create(:upload, model: project)
    end

    it 'updates project statistics when upload is added' do
      expect(ProjectCacheWorker).to receive(:perform_async)
        .with(project.id, [], ['uploads_size'])

      subject.save!
    end

    it 'updates project statistics when upload is removed' do
      subject.save!

      expect(ProjectCacheWorker).to receive(:perform_async)
        .with(project.id, [], ['uploads_size'])

      subject.destroy!
    end
  end
end
