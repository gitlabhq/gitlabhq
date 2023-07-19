# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LfsObjectsProject do
  let_it_be(:project) { create(:project) }

  subject do
    create(:lfs_objects_project, project: project)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:lfs_object) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:lfs_object_id) }
    it { is_expected.to validate_presence_of(:project_id) }

    it 'validates object id' do
      is_expected.to validate_uniqueness_of(:lfs_object_id)
        .scoped_to(:project_id, :repository_type)
        .with_message("already exists in repository")
    end
  end

  describe '#link_to_project!' do
    it 'does not throw error when duplicate exists' do
      subject

      expect do
        result = described_class.link_to_project!(subject.lfs_object, subject.project)
        expect(result).to be_a(described_class)
      end.not_to change { described_class.count }
    end

    it 'upserts a new entry and updates the project cache' do
      new_project = create(:project)

      allow(ProjectCacheWorker).to receive(:perform_async).and_call_original
      expect(ProjectCacheWorker).to receive(:perform_async).with(new_project.id, [], [:lfs_objects_size])
      expect { described_class.link_to_project!(subject.lfs_object, new_project) }
        .to change { described_class.count }

      expect(described_class.find_by(lfs_object_id: subject.lfs_object.id, project_id: new_project.id)).to be_present
    end
  end

  describe '#update_project_statistics' do
    it 'updates project statistics when the object is added' do
      expect(ProjectCacheWorker).to receive(:perform_async)
        .with(project.id, [], [:lfs_objects_size])

      subject.save!
    end

    it 'updates project statistics when the object is removed' do
      subject.save!

      expect(ProjectCacheWorker).to receive(:perform_async)
        .with(project.id, [], [:lfs_objects_size])

      subject.destroy!
    end
  end
end
