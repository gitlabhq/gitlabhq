# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::BackfillProjectFullpathInRepoConfig, :migration, schema: 20181010133639 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:group) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:subgroup) { namespaces.create!(name: 'bar', path: 'bar', parent_id: group.id) }

  describe described_class::Storage::HashedProject do
    let(:project) { double(id: 555) }

    subject(:project_storage) { described_class.new(project) }

    it 'has the correct disk_path' do
      expect(project_storage.disk_path).to eq('@hashed/91/a7/91a73fd806ab2c005c13b4dc19130a884e909dea3f72d46e30266fe1a1f588d8')
    end
  end

  describe described_class::Storage::LegacyProject do
    let(:project) { double(full_path: 'this/is/the/full/path') }

    subject(:project_storage) { described_class.new(project) }

    it 'has the correct disk_path' do
      expect(project_storage.disk_path).to eq('this/is/the/full/path')
    end
  end

  describe described_class::Project do
    let(:project_record) { projects.create!(namespace_id: subgroup.id, name: 'baz', path: 'baz') }

    subject(:project) { described_class.find(project_record.id) }

    describe '#full_path' do
      it 'returns path containing all parent namespaces' do
        expect(project.full_path).to eq('foo/bar/baz')
      end

      it 'raises OrphanedNamespaceError when any parent namespace does not exist' do
        subgroup.update_attribute(:parent_id, namespaces.maximum(:id).succ)

        expect { project.full_path }.to raise_error(Gitlab::BackgroundMigration::BackfillProjectFullpathInRepoConfig::OrphanedNamespaceError)
      end
    end
  end

  describe described_class::Up do
    describe '#perform' do
      subject(:migrate) { described_class.new.perform(projects.minimum(:id), projects.maximum(:id)) }

      it 'asks the gitaly client to set config' do
        projects.create!(namespace_id: subgroup.id, name: 'baz', path: 'baz')
        projects.create!(namespace_id: subgroup.id, name: 'buzz', path: 'buzz', storage_version: 1)

        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |repository_service|
          allow(repository_service).to receive(:cleanup)
          expect(repository_service).to receive(:set_config).with('gitlab.fullpath' => 'foo/bar/baz')
        end

        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |repository_service|
          allow(repository_service).to receive(:cleanup)
          expect(repository_service).to receive(:set_config).with('gitlab.fullpath' => 'foo/bar/buzz')
        end

        migrate
      end
    end
  end

  describe described_class::Down do
    describe '#perform' do
      subject(:migrate) { described_class.new.perform(projects.minimum(:id), projects.maximum(:id)) }

      it 'asks the gitaly client to set config' do
        projects.create!(namespace_id: subgroup.id, name: 'baz', path: 'baz')

        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |repository_service|
          allow(repository_service).to receive(:cleanup)
          expect(repository_service).to receive(:delete_config).with(['gitlab.fullpath'])
        end

        migrate
      end
    end
  end
end
