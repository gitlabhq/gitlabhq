# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('db', 'post_migrate', '20181010133639_backfill_store_project_full_path_in_repo.rb')

describe BackfillStoreProjectFullPathInRepo, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:group) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:subgroup) { namespaces.create!(name: 'bar', path: 'bar', parent_id: group.id) }

  subject(:migration) { described_class.new }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  describe '#up' do
    shared_examples_for 'writes the full path to git config' do
      it 'writes the git config' do
        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |repository_service|
          allow(repository_service).to receive(:cleanup)
          expect(repository_service).to receive(:set_config).with('gitlab.fullpath' => expected_path)
        end

        migration.up
      end

      it 'retries in case of failure' do
        repository_service = spy(:repository_service)

        allow(Gitlab::GitalyClient::RepositoryService).to receive(:new).and_return(repository_service)

        allow(repository_service).to receive(:set_config).and_raise(GRPC::BadStatus, 'Retry me')
        expect(repository_service).to receive(:set_config).exactly(3).times

        migration.up
      end

      it 'cleans up repository before writing the config' do
        expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |repository_service|
          expect(repository_service).to receive(:cleanup).ordered
          expect(repository_service).to receive(:set_config).ordered
        end

        migration.up
      end

      context 'legacy storage' do
        it 'finds the repository at the correct location' do
          Project.find(project.id).create_repository

          expect { migration.up }.not_to raise_error
        end
      end

      context 'hashed storage' do
        it 'finds the repository at the correct location' do
          project.update_attribute(:storage_version, 1)

          Project.find(project.id).create_repository

          expect { migration.up }.not_to raise_error
        end
      end
    end

    context 'project in group' do
      let!(:project) { projects.create!(namespace_id: group.id, name: 'baz', path: 'baz') }
      let(:expected_path) { 'foo/baz' }

      it_behaves_like 'writes the full path to git config'
    end

    context 'project in subgroup' do
      let!(:project) { projects.create!(namespace_id: subgroup.id, name: 'baz', path: 'baz') }
      let(:expected_path) { 'foo/bar/baz' }

      it_behaves_like 'writes the full path to git config'
    end
  end

  describe '#down' do
    context 'project in group' do
      let!(:project) { projects.create!(namespace_id: group.id, name: 'baz', path: 'baz') }

      it 'deletes the gitlab full config value' do
        expect_any_instance_of(Gitlab::GitalyClient::RepositoryService)
          .to receive(:delete_config).with(['gitlab.fullpath'])

        migration.down
      end
    end
  end
end
