require 'spec_helper'

describe GeoNodeStatus do
  subject { described_class.new }

  describe '#healthy?' do
    context 'when health is blank' do
      it 'returns true' do
        subject.health = ''

        expect(subject.healthy?).to eq true
      end
    end

    context 'when health is present' do
      it 'returns false' do
        subject.health = 'something went wrong'

        expect(subject.healthy?).to eq false
      end
    end
  end

  describe '#health' do
    it 'delegates to the HealthCheck' do
      subject.health = nil

      expect(HealthCheck::Utils).to receive(:process_checks).with(['geo']).once

      subject.health
    end
  end

  describe '#attachments_synced_count' do
    it 'does not count synced files that were replaced' do
      user = create(:user, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png'))

      subject = described_class.new
      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(0)

      upload = Upload.find_by(model: user, uploader: 'AvatarUploader')
      Geo::FileRegistry.create(file_type: :avatar, file_id: upload.id)

      subject = described_class.new
      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(1)

      user.update(avatar: fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg'))

      subject = described_class.new
      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(0)

      upload = Upload.find_by(model: user, uploader: 'AvatarUploader')
      Geo::FileRegistry.create(file_type: :avatar, file_id: upload.id)

      subject = described_class.new
      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(1)
    end
  end

  describe '#attachments_synced_in_percentage' do
    it 'returns 0 when no objects are available' do
      subject.attachments_count = 0
      subject.attachments_synced_count = 0

      expect(subject.attachments_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage' do
      subject.attachments_count = 4
      subject.attachments_synced_count = 1

      expect(subject.attachments_synced_in_percentage).to be_within(0.0001).of(25)
    end
  end

  describe '#lfs_objects_synced_in_percentage' do
    it 'returns 0 when no objects are available' do
      subject.lfs_objects_count = 0
      subject.lfs_objects_synced_count = 0

      expect(subject.lfs_objects_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage' do
      subject.lfs_objects_count = 4
      subject.lfs_objects_synced_count = 1

      expect(subject.lfs_objects_synced_in_percentage).to be_within(0.0001).of(25)
    end
  end

  describe '#repositories_synced_in_percentage' do
    it 'returns 0 when no objects are available' do
      subject.repositories_count = 0
      subject.repositories_synced_count = 0

      expect(subject.repositories_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage' do
      subject.repositories_count = 4
      subject.repositories_synced_count = 1

      expect(subject.repositories_synced_in_percentage).to be_within(0.0001).of(25)
    end
  end

  context 'when no values are available' do
    it 'returns 0 for each attribute' do
      subject.attachments_count = nil
      subject.attachments_synced_count = nil
      subject.lfs_objects_count = nil
      subject.lfs_objects_synced_count = nil
      subject.repositories_count = nil
      subject.repositories_synced_count = nil
      subject.repositories_failed_count = nil

      expect(subject.repositories_count).to be_zero
      expect(subject.repositories_synced_count).to be_zero
      expect(subject.repositories_synced_in_percentage).to be_zero
      expect(subject.repositories_failed_count).to be_zero
      expect(subject.lfs_objects_count).to be_zero
      expect(subject.lfs_objects_synced_count).to be_zero
      expect(subject.lfs_objects_synced_in_percentage).to be_zero
      expect(subject.attachments_count).to be_zero
      expect(subject.attachments_synced_count).to be_zero
      expect(subject.attachments_synced_in_percentage).to be_zero
    end
  end
end
