# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PoolRepositories::DeadShardMemberRemediator, feature_category: :source_code_management do
  let_it_be(:dead_shard) { create(:shard, name: 'nfs-file99') }
  let_it_be(:live_shard) { Shard.by_name(Gitlab.config.repositories.storages.each_key.first) }
  let_it_be(:organization) { create(:organization) }
  let_it_be_with_reload(:dead_pool) do
    create(:pool_repository, :without_project, shard: dead_shard, organization: organization,
      disk_path: '@pools/ab/cd/abcd1234')
  end

  let_it_be_with_reload(:silently_linked_project) do
    create(:project, pool_repository: dead_pool)
  end

  let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }
  let(:output_file) { File.join(Dir.tmpdir, "remediation_#{SecureRandom.hex(8)}.csv") }
  let(:input_file) { File.join(Dir.tmpdir, "classification_#{SecureRandom.hex(8)}.csv") }
  let(:dry_run) { true }
  let(:classifications) { %w[silently_linked] }

  let(:remediator) do
    described_class.new(
      input_file: input_file,
      output_file: output_file,
      logger: logger,
      dry_run: dry_run,
      classifications: classifications
    )
  end

  subject(:run_remediation) { remediator.run! }

  before do
    write_classification_csv
  end

  after do
    FileUtils.rm_f(output_file)
    FileUtils.rm_f(input_file)
  end

  def write_classification_csv
    CSV.open(input_file, 'w') do |csv|
      csv << ['Pool ID', 'Pool Shard Name (dead)', 'Pool Disk Path', 'Project ID', 'Project Path',
        'Project Shard (current)', 'Classification', 'Gitaly Pool Path', 'Notes']
      csv << [dead_pool.id, dead_shard.name, dead_pool.disk_path, silently_linked_project.id,
        silently_linked_project.full_path, silently_linked_project.repository_storage,
        'silently_linked', '@pools/ab/cd/abcd1234.git',
        "Linked to on-disk pool: @pools/ab/cd/abcd1234.git on #{live_shard.name}"]
    end
  end

  def output_csv_rows
    CSV.read(output_file, headers: true)
  end

  describe '#run!' do
    it 'completes without errors' do
      expect { run_remediation }.not_to raise_error
    end

    it 'writes CSV output with headers' do
      run_remediation

      rows = CSV.read(output_file)
      expect(rows.first).to include('Project ID', 'Action', 'Status')
    end
  end

  describe 'validation' do
    context 'when input file does not exist' do
      it 'raises ValidationError' do
        FileUtils.rm_f(input_file)

        expect { run_remediation }.to raise_error(described_class::ValidationError, /does not exist/)
      end
    end

    context 'when no classifications specified' do
      let(:classifications) { [] }

      it 'raises ValidationError' do
        expect { run_remediation }.to raise_error(described_class::ValidationError, /No valid classifications/)
      end
    end

    context 'when unknown classifications specified' do
      let(:classifications) { %w[silently_linked bogus] }

      it 'raises ValidationError' do
        expect { run_remediation }.to raise_error(described_class::ValidationError, /Unknown classifications: bogus/)
      end
    end

    context 'when output file already exists' do
      before do
        File.write(output_file, 'existing data')
      end

      it 'raises ValidationError' do
        expect { run_remediation }.to raise_error(described_class::ValidationError, /already exists/)
      end
    end
  end

  describe 'dry run' do
    let(:dry_run) { true }

    it 'does not modify projects' do
      run_remediation

      expect(silently_linked_project.reload.pool_repository_id).to eq(dead_pool.id)
    end

    it 'does not create new pool repositories' do
      expect { run_remediation }.not_to change { PoolRepository.count }
    end

    it 'reports counts' do
      run_remediation

      expect(remediator.results['relinked']).to eq(1)
    end

    it 'writes dry run status to output CSV' do
      run_remediation

      statuses = output_csv_rows.map { |r| r['Status'] }
      expect(statuses).to all(eq('dry_run'))
    end
  end

  describe 'live run' do
    let(:dry_run) { false }

    describe 'silently_linked remediation' do
      let(:classifications) { ['silently_linked'] }

      it 'creates a new pool on the live shard' do
        expect { run_remediation }.to change { PoolRepository.count }.by(1)
      end

      it 'relinks the project to the new pool' do
        run_remediation

        new_pool = silently_linked_project.reload.pool_repository
        expect(new_pool).not_to eq(dead_pool)
        expect(new_pool.shard_name).to eq(live_shard.name)
        expect(new_pool.disk_path).to eq(dead_pool.disk_path)
        expect(new_pool.state).to eq('ready')
      end

      it 'preserves the organization on the new pool' do
        run_remediation

        new_pool = silently_linked_project.reload.pool_repository
        expect(new_pool.organization).to eq(organization)
      end

      it 'reuses existing pool on the same shard' do
        existing_pool = create(:pool_repository, :without_project, shard: live_shard,
          organization: organization, disk_path: dead_pool.disk_path, state: 'ready')

        expect { run_remediation }.not_to change { PoolRepository.count }

        expect(silently_linked_project.reload.pool_repository).to eq(existing_pool)
      end

      it 'writes success status to output CSV' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == silently_linked_project.id.to_s }
        expect(row['Status']).to eq('success')
        expect(row['Action']).to eq('relinked')
      end

      it 'does not mark dead pool obsolete' do
        run_remediation

        expect(dead_pool.reload.state).not_to eq('obsolete')
      end
    end
  end

  describe 'classification filter' do
    let(:dry_run) { false }

    context 'when CSV row classification is not in target list' do
      let_it_be_with_reload(:other_project) do
        create(:project, pool_repository: dead_pool)
      end

      before do
        CSV.open(input_file, 'w') do |csv|
          csv << ['Pool ID', 'Pool Shard Name (dead)', 'Pool Disk Path', 'Project ID', 'Project Path',
            'Project Shard (current)', 'Classification', 'Gitaly Pool Path', 'Notes']
          csv << [dead_pool.id, dead_shard.name, dead_pool.disk_path, other_project.id,
            other_project.full_path, other_project.repository_storage,
            'self_contained', '', 'No object pool linked on current shard']
        end
      end

      it 'skips the row and leaves the project unchanged' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == other_project.id.to_s }
        expect(row['Status']).to eq('skipped')
        expect(row['Notes']).to include('not in target list')
        expect(remediator.results['skipped']).to eq(1)
        expect(other_project.reload.pool_repository_id).to eq(dead_pool.id)
      end
    end
  end

  describe 'staleness check' do
    let(:dry_run) { false }

    context 'when project pool_repository_id has changed since classification' do
      let(:classifications) { ['silently_linked'] }

      before do
        silently_linked_project.update_column(:pool_repository_id, nil)
      end

      it 'skips the project' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == silently_linked_project.id.to_s }
        expect(row['Status']).to eq('skipped')
        expect(row['Notes']).to include('Stale')
      end

      it 'increments skipped counter' do
        run_remediation

        expect(remediator.results['skipped']).to be >= 1
      end
    end

    context 'when pool_repository_id changes after lock inside transaction' do
      let(:classifications) { ['silently_linked'] }

      before do
        allow_next_found_instance_of(Project) do |project|
          allow(project).to receive(:lock!).and_wrap_original do |method|
            Project.where(id: project.id).update_all(pool_repository_id: nil)
            method.call
          end
        end
      end

      it 'rolls back and skips the project' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == silently_linked_project.id.to_s }
        expect(row['Status']).to eq('skipped')
        expect(row['Notes']).to include('pool_repository_id changed')
      end
    end

    context 'when silently_linked project was already relinked' do
      let(:classifications) { ['silently_linked'] }
      let_it_be(:other_pool) do
        create(:pool_repository, :without_project, shard: live_shard, organization: organization,
          disk_path: '@pools/xx/yy/xxyy5678')
      end

      before do
        silently_linked_project.update_column(:pool_repository_id, other_pool.id)
      end

      it 'skips the project' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == silently_linked_project.id.to_s }
        expect(row['Status']).to eq('skipped')
        expect(row['Notes']).to include('Stale')
      end
    end

    context 'when project moved shards since classification' do
      let(:classifications) { ['silently_linked'] }

      before do
        CSV.open(input_file, 'w') do |csv|
          csv << ['Pool ID', 'Pool Shard Name (dead)', 'Pool Disk Path', 'Project ID', 'Project Path',
            'Project Shard (current)', 'Classification', 'Gitaly Pool Path', 'Notes']
          csv << [dead_pool.id, dead_shard.name, dead_pool.disk_path, silently_linked_project.id,
            silently_linked_project.full_path, 'old-shard-name',
            'silently_linked', '@pools/ab/cd/abcd1234.git', '']
        end
      end

      it 'skips the project' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == silently_linked_project.id.to_s }
        expect(row['Status']).to eq('skipped')
        expect(row['Notes']).to include('project moved to')
      end
    end

    context 'when on-disk pool path does not match dead pool disk_path' do
      let(:classifications) { ['silently_linked'] }

      before do
        CSV.open(input_file, 'w') do |csv|
          csv << ['Pool ID', 'Pool Shard Name (dead)', 'Pool Disk Path', 'Project ID', 'Project Path',
            'Project Shard (current)', 'Classification', 'Gitaly Pool Path', 'Notes']
          csv << [dead_pool.id, dead_shard.name, dead_pool.disk_path, silently_linked_project.id,
            silently_linked_project.full_path, silently_linked_project.repository_storage,
            'silently_linked', '@pools/xx/yy/different.git', '']
        end
      end

      it 'skips the project' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == silently_linked_project.id.to_s }
        expect(row['Status']).to eq('skipped')
        expect(row['Notes']).to include('on-disk pool')
        expect(row['Notes']).to include('does not match')
      end
    end
  end

  describe 'live shard safety check' do
    let(:dry_run) { false }
    let(:classifications) { ['silently_linked'] }

    context 'when dead pool shard is still configured' do
      let_it_be(:live_pool) do
        create(:pool_repository, :without_project, shard: live_shard, organization: organization,
          disk_path: '@pools/zz/yy/zzyy9999')
      end

      let_it_be_with_reload(:live_shard_project) do
        create(:project, pool_repository: live_pool)
      end

      before do
        CSV.open(input_file, 'w') do |csv|
          csv << ['Pool ID', 'Pool Shard Name (dead)', 'Pool Disk Path', 'Project ID', 'Project Path',
            'Project Shard (current)', 'Classification', 'Gitaly Pool Path', 'Notes']
          csv << [live_pool.id, live_shard.name, live_pool.disk_path, live_shard_project.id,
            live_shard_project.full_path, live_shard_project.repository_storage,
            'silently_linked', "#{live_pool.disk_path}.git", '']
        end
      end

      it 'skips the project' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == live_shard_project.id.to_s }
        expect(row['Status']).to eq('skipped')
        expect(row['Notes']).to include('still configured')
      end

      it 'does not modify the project' do
        run_remediation

        expect(live_shard_project.reload.pool_repository_id).to eq(live_pool.id)
      end
    end
  end

  describe 'missing records' do
    let(:dry_run) { false }
    let(:classifications) { ['silently_linked'] }

    context 'when project does not exist' do
      before do
        CSV.open(input_file, 'w') do |csv|
          csv << ['Pool ID', 'Pool Shard Name (dead)', 'Pool Disk Path', 'Project ID', 'Project Path',
            'Project Shard (current)', 'Classification', 'Gitaly Pool Path', 'Notes']
          csv << [dead_pool.id, dead_shard.name, dead_pool.disk_path, 0,
            'deleted/project', 'default', 'silently_linked', "#{dead_pool.disk_path}.git", '']
        end
      end

      it 'skips with a not found note' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == '0' }
        expect(row['Status']).to eq('skipped')
        expect(row['Notes']).to include('Not found')
      end
    end

    context 'when pool repository does not exist' do
      before do
        CSV.open(input_file, 'w') do |csv|
          csv << ['Pool ID', 'Pool Shard Name (dead)', 'Pool Disk Path', 'Project ID', 'Project Path',
            'Project Shard (current)', 'Classification', 'Gitaly Pool Path', 'Notes']
          csv << [0, dead_shard.name, dead_pool.disk_path, silently_linked_project.id,
            silently_linked_project.full_path, silently_linked_project.repository_storage,
            'silently_linked', "#{dead_pool.disk_path}.git", '']
        end
      end

      it 'skips with a not found note' do
        run_remediation

        row = output_csv_rows.find { |r| r['Project ID'] == silently_linked_project.id.to_s }
        expect(row['Status']).to eq('skipped')
        expect(row['Notes']).to include('Not found')
      end
    end
  end

  describe 'non-ready existing pool' do
    let(:dry_run) { false }
    let(:classifications) { ['silently_linked'] }

    it 'skips when existing pool on target shard is not ready' do
      create(:pool_repository, :without_project, shard: live_shard,
        organization: organization, disk_path: dead_pool.disk_path, state: 'obsolete')

      run_remediation

      row = output_csv_rows.find { |r| r['Project ID'] == silently_linked_project.id.to_s }
      expect(row['Status']).to eq('skipped')
      expect(row['Notes']).to include('obsolete')
    end
  end

  describe 'error handling' do
    let(:dry_run) { false }
    let(:classifications) { ['silently_linked'] }

    before do
      allow(Project).to receive(:find).with(silently_linked_project.id.to_s).and_raise(StandardError, 'db error')
    end

    it 'logs the error and continues' do
      run_remediation

      expect(logger).to have_received(:error).with(/Error remediating project/)
      expect(remediator.results['error']).to eq(1)
    end

    it 'writes error status to output CSV' do
      run_remediation

      row = output_csv_rows.find { |r| r['Project ID'] == silently_linked_project.id.to_s }
      expect(row['Status']).to eq('error')
    end
  end

  describe 'csv_writer cleanup' do
    it 'closes csv_writer even when error occurs' do
      csv_writer_double = instance_double(Gitlab::PoolRepositories::CsvWriter,
        write_row: nil, flush: nil, close: nil)
      allow(Gitlab::PoolRepositories::CsvWriter).to receive(:new).and_return(csv_writer_double)
      allow(remediator).to receive(:process_csv).and_raise(StandardError, 'test')

      expect(csv_writer_double).to receive(:close)
      expect { remediator.run! }.to raise_error(StandardError)
    end
  end
end
