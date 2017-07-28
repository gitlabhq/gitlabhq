require 'spec_helper'

describe GeoNodeStatus do
  let!(:geo_node) { create(:geo_node, :current) }
  let(:group)      { create(:group) }
  let!(:project_1) { create(:empty_project, group: group) }
  let!(:project_2) { create(:empty_project, group: group) }
  let!(:project_3) { create(:empty_project) }
  let!(:project_4) { create(:empty_project) }

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
      create(:geo_file_registry, :avatar, file_id: upload.id)

      subject = described_class.new
      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(1)

      user.update(avatar: fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg'))

      subject = described_class.new
      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(0)

      upload = Upload.find_by(model: user, uploader: 'AvatarUploader')
      create(:geo_file_registry, :avatar, file_id: upload.id)

      subject = described_class.new
      expect(subject.attachments_count).to eq(1)
      expect(subject.attachments_synced_count).to eq(1)
    end
  end

  describe '#attachments_synced_in_percentage' do
    let(:avatar) { fixture_file_upload(Rails.root.join('spec/fixtures/dk.png')) }
    let(:upload_1) { create(:upload, model: group, path: avatar) }
    let(:upload_2) { create(:upload, model: project_1, path: avatar) }

    before do
      create(:upload, model: create(:group), path: avatar)
      create(:upload, model: project_3, path: avatar)
    end

    it 'returns 0 when no objects are available' do
      expect(subject.attachments_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_file_registry, :avatar, file_id: upload_1.id)
      create(:geo_file_registry, :avatar, file_id: upload_2.id)

      expect(subject.attachments_synced_in_percentage).to be_within(0.0001).of(50)
    end

    it 'returns the right percentage with group restrictions' do
      geo_node.update_attribute(:groups, [group])
      create(:geo_file_registry, :avatar, file_id: upload_1.id)
      create(:geo_file_registry, :avatar, file_id: upload_2.id)

      expect(subject.attachments_synced_in_percentage).to be_within(0.0001).of(100)
    end
  end

  describe '#lfs_objects_synced_in_percentage' do
    let(:lfs_object_project) { create(:lfs_objects_project, project: project_1) }

    before do
      allow(ProjectCacheWorker).to receive(:perform_async).and_return(true)

      create(:lfs_objects_project, project: project_1)
      create_list(:lfs_objects_project, 2, project: project_3)
    end

    it 'returns 0 when no objects are available' do
      expect(subject.lfs_objects_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_file_registry, :lfs, file_id: lfs_object_project.lfs_object_id)

      expect(subject.lfs_objects_synced_in_percentage).to be_within(0.0001).of(25)
    end

    it 'returns the right percentage with group restrictions' do
      geo_node.update_attribute(:groups, [group])
      create(:geo_file_registry, :lfs, file_id: lfs_object_project.lfs_object_id)

      expect(subject.lfs_objects_synced_in_percentage).to be_within(0.0001).of(50)
    end
  end

  describe '#repositories_synced_in_percentage' do
    it 'returns 0 when no projects are available' do
      expect(subject.repositories_synced_in_percentage).to eq(0)
    end

    it 'returns the right percentage with no group restrictions' do
      create(:geo_project_registry, :synced, project: project_1)

      expect(subject.repositories_synced_in_percentage).to be_within(0.0001).of(25)
    end

    it 'returns the right percentage with group restrictions' do
      geo_node.update_attribute(:groups, [group])
      create(:geo_project_registry, :synced, project: project_1)

      expect(subject.repositories_synced_in_percentage).to be_within(0.0001).of(50)
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
