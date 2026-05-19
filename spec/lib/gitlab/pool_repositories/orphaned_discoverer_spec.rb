# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PoolRepositories::OrphanedDiscoverer, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:pool) { create(:pool_repository, source_project: project) }

  let(:logger) { instance_double(Logger, info: nil, error: nil, debug: nil) }
  let(:verbose) { false }
  let(:temp_output_file) { Tempfile.new('orphaned_pools.csv') }
  let(:output_file) { temp_output_file.path }
  let(:storage_scanner) do
    instance_double(Gitlab::PoolRepositories::StorageScanner, scan_all_storages: nil, orphaned_pools: [])
  end

  let(:discoverer) do
    described_class.new(logger: logger, output_file: output_file, verbose: verbose, storage_scanner: storage_scanner)
  end

  subject(:run_discovery) { discoverer.run! }

  before_all do
    project.update!(pool_repository: pool)
  end

  before do
    stub_repository_access
  end

  after do
    temp_output_file.close
    temp_output_file.unlink
  end

  def stub_repository_access(object_pool: nil)
    allow_next_instance_of(Repository) do |instance|
      allow(instance).to receive_messages(exists?: true, object_pool: object_pool)
    end
  end

  def csv_rows
    CSV.read(temp_output_file.path)
  end

  def csv_data_rows
    csv_rows.drop(1)
  end

  def orphaned_pools_with_reason(reason_code)
    discoverer.orphaned_pools.select { |p| p[:reason_codes].include?(reason_code) }
  end

  describe '#run!' do
    it 'completes without errors' do
      expect { run_discovery }.not_to raise_error
    end

    it 'sets extended statement timeout during discovery' do
      expect(ApplicationRecord.connection).to receive(:execute)
        .with("SET statement_timeout = '5min'").ordered
      expect(ApplicationRecord.connection).to receive(:execute)
        .with('RESET statement_timeout').ordered

      run_discovery
    end

    it 'closes csv_writer in ensure block even when error occurs' do
      csv_writer = instance_double(Gitlab::PoolRepositories::CsvWriter, write_row: nil)
      discoverer = described_class.new(logger: logger, output_file: output_file, verbose: verbose,
        csv_writer: csv_writer)

      allow(discoverer).to receive(:discover_orphaned_pools).and_raise(StandardError, 'Scan error')

      expect(csv_writer).to receive(:close)
      expect { discoverer.run! }.to raise_error(StandardError)
    end

    context 'when output_file is not provided' do
      it 'raises ArgumentError' do
        expect do
          described_class.new(logger: logger, output_file: nil, verbose: verbose)
        end.to raise_error(ArgumentError, 'output_file is required')
      end

      it 'raises ArgumentError when output_file is blank' do
        expect do
          described_class.new(logger: logger, output_file: '', verbose: verbose)
        end.to raise_error(ArgumentError, 'output_file is required')
      end
    end
  end

  describe 'pool associations and state checks' do
    context 'when pool has no source project' do
      before do
        pool.update_column(:source_project_id, nil)
      end

      after do
        pool.update_column(:source_project_id, project.id)
      end

      it 'detects pool_no_source_project' do
        run_discovery

        expect(orphaned_pools_with_reason('pool_no_source_project').size).to eq(1)
        expect(discoverer.orphaned_pools.first[:pool_id]).to eq(pool.id)
      end

      it 'writes the orphan to CSV' do
        run_discovery

        expect(csv_data_rows.size).to eq(1)
        expect(csv_data_rows.first).to include(pool.id.to_s)
      end
    end

    context 'when pool is in obsolete state' do
      before do
        pool.update_column(:state, 'obsolete')
      end

      after do
        pool.update_column(:state, 'none')
      end

      it 'detects pool_in_obsolete_state' do
        run_discovery

        expect(orphaned_pools_with_reason('pool_in_obsolete_state').size).to eq(1)
      end
    end

    context 'when pool has no member projects' do
      before do
        project.update_column(:pool_repository_id, nil)
      end

      after do
        project.update_column(:pool_repository_id, pool.id)
      end

      it 'detects pool_in_db_no_projects' do
        run_discovery

        expect(orphaned_pools_with_reason('pool_in_db_no_projects').size).to eq(1)
      end
    end

    context 'when pool has multiple orphan reasons' do
      before do
        pool.update_columns(source_project_id: nil, state: 'obsolete')
        project.update_column(:pool_repository_id, nil)
      end

      after do
        pool.update_columns(source_project_id: project.id, state: 'none')
        project.update_column(:pool_repository_id, pool.id)
      end

      it 'includes all applicable reason codes' do
        run_discovery

        record = discoverer.orphaned_pools.first
        expect(record[:reason_codes]).to include('pool_no_source_project')
        expect(record[:reason_codes]).to include('pool_in_obsolete_state')
        expect(record[:reason_codes]).to include('pool_in_db_no_projects')
      end
    end

    context 'when pool has state issues and a disk path mismatch' do
      before do
        pool.update_column(:source_project_id, nil)
        stub_repository_access(
          object_pool: instance_double(Gitlab::Git::ObjectPool, relative_path: '@pools/different.git')
        )
      end

      after do
        pool.update_column(:source_project_id, project.id)
      end

      it 'combines all reasons into a single record' do
        run_discovery

        matching = discoverer.orphaned_pools.select { |p| p[:pool_id] == pool.id }
        expect(matching.size).to eq(1)
        expect(matching.first[:reason_codes]).to include('pool_no_source_project')
        expect(matching.first[:reason_codes]).to include('disk_path_mismatch')
      end
    end

    context 'when pool is healthy' do
      it 'does not report any orphan' do
        run_discovery

        expect(discoverer.orphaned_pools).to be_empty
      end

      it 'writes only CSV headers' do
        run_discovery

        expect(csv_data_rows).to be_empty
      end
    end

    context 'when multiple pools have different reasons' do
      let_it_be(:pool2) { create(:pool_repository) }

      before do
        pool.update_column(:source_project_id, nil)
        pool2.update_column(:state, 'obsolete')
      end

      after do
        pool.update_column(:source_project_id, project.id)
        pool2.update_column(:state, 'none')
      end

      it 'records each pool separately' do
        run_discovery

        expect(discoverer.orphaned_pools.size).to eq(2)
      end
    end
  end

  describe 'disk path mismatch detection' do
    context 'when paths do not match' do
      before do
        stub_repository_access(
          object_pool: instance_double(Gitlab::Git::ObjectPool, relative_path: '@pools/different.git')
        )
      end

      it 'detects disk_path_mismatch' do
        run_discovery

        expect(orphaned_pools_with_reason('disk_path_mismatch').size).to eq(1)
      end
    end

    context 'when Gitaly pool is nil' do
      before do
        stub_repository_access(object_pool: nil)
      end

      it 'does not report disk_path_mismatch' do
        run_discovery

        expect(orphaned_pools_with_reason('disk_path_mismatch')).to be_empty
      end
    end

    context 'when the repository does not exist' do
      before do
        allow_next_instance_of(Repository) do |instance|
          allow(instance).to receive(:exists?).and_return(false)
        end
      end

      it 'handles gracefully' do
        expect { run_discovery }.not_to raise_error
      end
    end

    context 'when fetching the Gitaly pool raises an error' do
      before do
        allow_next_instance_of(Repository) do |instance|
          allow(instance).to receive(:exists?).and_raise(StandardError, 'Repository error')
        end
      end

      context 'when verbose' do
        let(:verbose) { true }

        it 'logs the error via debug' do
          run_discovery

          expect(logger).to have_received(:debug).with(/Failed to fetch Gitaly pool/)
        end
      end

      context 'when not verbose' do
        it 'does not log via debug' do
          run_discovery

          expect(logger).not_to have_received(:debug)
        end
      end
    end

    context 'when paths match' do
      before do
        stub_repository_access(
          object_pool: instance_double(Gitlab::Git::ObjectPool, relative_path: "#{pool.disk_path}.git")
        )
      end

      it 'does not report any orphan' do
        run_discovery

        expect(discoverer.orphaned_pools).to be_empty
      end
    end

    context 'with multiple member projects' do
      let_it_be(:project2) { create(:project) }

      before_all do
        project2.update!(pool_repository: pool)
      end

      def stub_repositories_for_projects(repo_stubs)
        allow_any_instance_of(Project).to receive(:repository) do |proj| # rubocop:disable RSpec/AnyInstanceOf -- Need to stub repositories on projects loaded via find_each
          repo_stubs[proj.id]
        end
      end

      context 'when first member project repository does not exist but second does' do
        let(:mismatched_path) { '@pools/different.git' }

        it 'detects disk_path_mismatch from second member project' do
          stub_repositories_for_projects(
            project.id => instance_double(Repository, exists?: false),
            project2.id => instance_double(Repository,
              exists?: true,
              object_pool: instance_double(Gitlab::Git::ObjectPool, relative_path: mismatched_path)
            )
          )

          run_discovery

          orphan = orphaned_pools_with_reason('disk_path_mismatch').first
          expect(orphan).to be_present
          expect(orphan[:relative_path]).to eq(mismatched_path)
        end
      end

      context 'when first member project fails but second has matching path' do
        it 'does not report disk_path_mismatch' do
          project1_repo = instance_double(Repository)
          allow(project1_repo).to receive(:exists?).and_raise(StandardError, 'Repository error')

          stub_repositories_for_projects(
            project.id => project1_repo,
            project2.id => instance_double(Repository,
              exists?: true,
              object_pool: instance_double(Gitlab::Git::ObjectPool, relative_path: "#{pool.disk_path}.git")
            )
          )

          run_discovery

          expect(orphaned_pools_with_reason('disk_path_mismatch')).to be_empty
        end
      end

      context 'when first member project has matching path' do
        it 'stops checking after first valid match and does not report mismatch' do
          project2_repo = instance_double(Repository,
            exists?: true,
            object_pool: instance_double(Gitlab::Git::ObjectPool, relative_path: '@pools/different.git')
          )

          stub_repositories_for_projects(
            project.id => instance_double(Repository,
              exists?: true,
              object_pool: instance_double(Gitlab::Git::ObjectPool, relative_path: "#{pool.disk_path}.git")
            ),
            project2.id => project2_repo
          )

          expect(project2_repo).not_to receive(:object_pool)

          run_discovery

          expect(orphaned_pools_with_reason('disk_path_mismatch')).to be_empty
        end
      end

      context 'when all member projects fail to fetch gitaly pool' do
        it 'does not report disk_path_mismatch' do
          stub_repositories_for_projects(
            project.id => instance_double(Repository, exists?: false),
            project2.id => instance_double(Repository, exists?: false)
          )

          run_discovery

          expect(orphaned_pools_with_reason('disk_path_mismatch')).to be_empty
        end
      end
    end
  end

  describe 'Gitaly storage scanning' do
    it 'concatenates orphaned pools from storage scanner' do
      orphaned_pool = { pool_id: 'N/A', disk_path: '@pools/test', reason_codes: 'pool_on_gitaly_missing_db' }
      allow(storage_scanner).to receive(:orphaned_pools).and_return([orphaned_pool])

      run_discovery

      expect(discoverer.orphaned_pools).to include(orphaned_pool)
    end
  end

  describe 'report_results' do
    context 'when no orphaned pools are found' do
      it 'reports no orphaned pools' do
        run_discovery

        expect(logger).to have_received(:info).with(/No orphaned pools detected!/)
      end
    end

    context 'when orphaned pools exist' do
      let_it_be(:pool2) { create(:pool_repository) }

      before do
        pool.update_column(:source_project_id, nil)
        pool2.update_column(:source_project_id, nil)
      end

      after do
        pool.update_column(:source_project_id, project.id)
      end

      it 'groups results by reason codes' do
        run_discovery

        expect(logger).to have_received(:info).with(/pool_no_source_project.*\(2\)/)
      end

      it 'logs output file location' do
        run_discovery

        expect(logger).to have_received(:info).with(/Detailed results saved to:/)
      end
    end
  end

  describe 'error handling' do
    context 'when checking a pool raises' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:check_pool).and_raise(StandardError, 'Pool error')
        end
      end

      it 'logs the error and continues' do
        expect { run_discovery }.not_to raise_error
        expect(logger).to have_received(:error).with(/Error checking pool #{pool.id}/)
      end

      context 'when verbose' do
        let(:verbose) { true }

        it 'logs the backtrace' do
          error = StandardError.new('Pool error')
          error.set_backtrace(%w[line1 line2])

          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:check_pool).and_raise(error)
          end

          run_discovery

          expect(logger).to have_received(:debug).with("line1\nline2")
        end
      end
    end
  end

  describe 'verbose logging' do
    before do
      pool.update_column(:source_project_id, nil)
    end

    after do
      pool.update_column(:source_project_id, project.id)
    end

    context 'when verbose' do
      let(:verbose) { true }

      it 'logs orphan details' do
        run_discovery

        expect(logger).to have_received(:info).with(/Found orphaned pool:/)
      end
    end

    context 'when not verbose' do
      it 'does not log orphan details' do
        run_discovery

        expect(logger).not_to have_received(:info).with(/Found orphaned pool:/)
      end
    end
  end
end
