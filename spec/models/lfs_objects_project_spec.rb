# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LfsObjectsProject, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }

  subject(:lfs_objects_project) do
    create(:lfs_objects_project, project: project)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:lfs_object) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:lfs_object_id) }
    it { is_expected.to validate_presence_of(:project_id) }

    it 'validates object id' do
      is_expected.to validate_uniqueness_of(:lfs_object_id)
        .scoped_to(:project_id, :repository_type)
        .with_message("already exists in repository")
    end
  end

  describe 'scopes' do
    let_it_be(:project_repository_type) { create(:lfs_objects_project, :project_repository_type, project: project) }
    let_it_be(:wiki_repository_type) { create(:lfs_objects_project, :wiki_repository_type, project: project) }
    let_it_be(:design_repository_type) { create(:lfs_objects_project, :design_repository_type, project: project) }
    let_it_be(:null_repository_type) { create(:lfs_objects_project, :null_repository_type, project: project) }

    describe 'project' do
      subject(:scope) { described_class.project }

      it { is_expected.to contain_exactly(project_repository_type) }
    end

    describe 'project_repository_type' do
      subject(:scope) { described_class.project_repository_type }

      it { is_expected.to contain_exactly(project_repository_type) }
    end

    describe 'wiki' do
      subject(:scope) { described_class.wiki }

      it { is_expected.to contain_exactly(wiki_repository_type) }
    end

    describe 'design' do
      subject(:scope) { described_class.design }

      it { is_expected.to contain_exactly(design_repository_type) }
    end
  end

  describe '#ensure_uniqueness' do
    let(:lfs_object) { create(:lfs_object) }

    subject(:lfs_objects_project) do
      build(:lfs_objects_project, project: project, lfs_object: lfs_object)
    end

    context 'when project_id is nil' do
      before do
        lfs_objects_project.project_id = nil
      end

      it 'does not execute advisory lock' do
        expect(lfs_objects_project.connection).not_to receive(:execute)
        lfs_objects_project.send(:ensure_uniqueness)
      end
    end

    context 'when lfs_object_id is nil' do
      before do
        lfs_objects_project.lfs_object_id = nil
      end

      it 'does not execute advisory lock' do
        expect(lfs_objects_project.connection).not_to receive(:execute)
        lfs_objects_project.send(:ensure_uniqueness)
      end
    end

    context 'when repository_type is nil' do
      before do
        lfs_objects_project.repository_type = nil
      end

      it 'executes advisory lock' do
        expect(lfs_objects_project.connection).to receive(:execute).with(/SELECT pg_advisory_xact_lock/)
        lfs_objects_project.send(:ensure_uniqueness)
      end

      it 'uses correct lock key' do
        lock_key = <<~LOCK_KEY.chomp
          #{lfs_objects_project.project_id}-#{lfs_objects_project.lfs_object_id}-null
        LOCK_KEY

        expect(lfs_objects_project.connection).to receive(:execute).with(/hashtext\('#{lock_key}'\)/)
        lfs_objects_project.send(:ensure_uniqueness)
      end
    end

    context 'when all conditions are met' do
      it 'executes advisory lock' do
        expect(lfs_objects_project.connection).to receive(:execute).with(/SELECT pg_advisory_xact_lock/)
        lfs_objects_project.send(:ensure_uniqueness)
      end

      it 'uses correct lock key' do
        lock_key = <<~LOCK_KEY.chomp
          #{lfs_objects_project.project_id}-#{lfs_objects_project.lfs_object_id}-#{lfs_objects_project.repository_type}
        LOCK_KEY

        expect(lfs_objects_project.connection).to receive(:execute).with(/hashtext\('#{lock_key}'\)/)
        lfs_objects_project.send(:ensure_uniqueness)
      end
    end
  end

  describe '#link_to_project!' do
    let(:repository_type) { :project }

    it 'does not throw error when duplicate exists' do
      lfs_objects_project

      expect do
        result = described_class.link_to_project!(
          lfs_objects_project.lfs_object,
          lfs_objects_project.project,
          repository_type
        )
        expect(result).to be_a(described_class)
      end.not_to change { described_class.count }
    end

    it 'upserts a new entry and updates the project cache' do
      new_project = create(:project)

      allow(ProjectCacheWorker).to receive(:perform_async).and_call_original
      expect(ProjectCacheWorker).to receive(:perform_async).with(new_project.id, [], %w[lfs_objects_size])
      expect { described_class.link_to_project!(lfs_objects_project.lfs_object, new_project, repository_type) }
        .to change { described_class.count }

      expect(described_class.find_by(
        lfs_object_id: lfs_objects_project.lfs_object.id,
        project_id: new_project.id
      )).to be_present
    end
  end

  describe '#update_project_statistics' do
    it 'updates project statistics when the object is added' do
      expect(ProjectCacheWorker).to receive(:perform_async)
        .with(project.id, [], %w[lfs_objects_size])

      lfs_objects_project.save!
    end

    it 'lfs_objects_project project statistics when the object is removed' do
      lfs_objects_project.save!

      expect(ProjectCacheWorker).to receive(:perform_async)
        .with(project.id, [], %w[lfs_objects_size])

      lfs_objects_project.destroy!
    end
  end
end
