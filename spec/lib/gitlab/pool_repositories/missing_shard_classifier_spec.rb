# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PoolRepositories::MissingShardClassifier, feature_category: :source_code_management do
  let_it_be(:dead_shard) { create(:shard, name: 'nfs-file99') }
  let_it_be(:organization) { create(:organization) }
  let_it_be_with_reload(:pool) do
    create(:pool_repository, :without_project, shard: dead_shard, organization: organization)
  end

  let_it_be_with_reload(:project) do
    create(:project, pool_repository: pool)
  end

  let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }
  let(:output_file) { File.join(Dir.tmpdir, "classification_#{SecureRandom.hex(8)}.csv") }
  let(:shard_names) { ['nfs-file99'] }

  let(:classifier) do
    described_class.new(
      shard_names: shard_names,
      logger: logger,
      output_file: output_file
    )
  end

  subject(:run_classification) { classifier.run! }

  after do
    FileUtils.rm_f(output_file)
  end

  def csv_rows
    CSV.read(output_file)
  end

  def csv_data_rows
    csv_rows.drop(1)
  end

  describe '#run!' do
    before do
      stub_repository_access
    end

    it 'completes without errors' do
      expect { run_classification }.not_to raise_error
    end

    it 'writes CSV headers' do
      run_classification

      headers = csv_rows.first
      expect(headers).to include('Pool ID', 'Classification', 'Project ID')
    end

    context 'when shard_names is empty' do
      it 'raises ValidationError' do
        expect do
          described_class.new(shard_names: [], logger: logger, output_file: output_file)
            .run!
        end.to raise_error(described_class::ValidationError, 'shard_names cannot be empty')
      end
    end

    context 'when output_file already exists' do
      it 'raises ValidationError and does not truncate the file' do
        existing_file = Tempfile.new('existing.csv')
        existing_file.write('previous audit data')
        existing_file.flush

        expect do
          described_class.new(shard_names: ['nfs-file99'], logger: logger, output_file: existing_file.path)
            .run!
        end.to raise_error(described_class::ValidationError, /already exists/)

        expect(File.read(existing_file.path)).to eq('previous audit data')
      ensure
        existing_file.close!
      end
    end

    context 'when no matching shards exist in database' do
      let(:shard_names) { ['nonexistent-shard'] }

      it 'logs and returns without error' do
        run_classification

        expect(logger).to have_received(:info).with(/No matching shards found/)
        expect(csv_data_rows).to be_empty
      end
    end
  end

  describe 'classification cases' do
    context 'when project repository has no object pool (self-contained)' do
      before do
        stub_repository_access(exists: true, object_pool: nil)
      end

      it 'classifies as self_contained' do
        run_classification

        expect(classifier.results['self_contained']).to eq(1)
        expect(csv_data_rows.first).to include('self_contained')
      end
    end

    context 'when project repository is linked to an on-disk pool (silently linked)' do
      let(:gitaly_pool) do
        instance_double(Gitlab::Git::ObjectPool, relative_path: '@pools/some/pool.git')
      end

      before do
        stub_repository_access(exists: true, object_pool: gitaly_pool)
      end

      it 'classifies as silently_linked' do
        run_classification

        expect(classifier.results['silently_linked']).to eq(1)
        expect(csv_data_rows.first).to include('silently_linked')
      end
    end

    context 'when project repository does not exist (broken)' do
      before do
        stub_repository_access(exists: false)
      end

      it 'classifies as broken' do
        run_classification

        expect(classifier.results['broken']).to eq(1)
        expect(csv_data_rows.first).to include('broken')
      end
    end

    context 'when fetching gitaly pool raises a transient Gitaly error' do
      before do
        allow_next_instance_of(Repository) do |repo|
          raw = instance_double(Gitlab::Git::Repository, exists?: true)
          allow(repo).to receive(:raw).and_return(raw)
          allow(repo).to receive(:object_pool)
            .and_raise(Gitlab::Git::CommandError, 'unavailable')
        end
      end

      it 'classifies as unknown' do
        run_classification

        expect(classifier.results['unknown']).to eq(1)
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow_next_instance_of(Repository) do |repo|
          raw = instance_double(Gitlab::Git::Repository)
          allow(repo).to receive(:raw).and_return(raw)
          allow(raw).to receive(:exists?).and_raise(StandardError, 'unexpected')
        end
      end

      it 'classifies as unknown and logs error' do
        run_classification

        expect(classifier.results['unknown']).to eq(1)
        expect(logger).to have_received(:error).with(/Error classifying project/)
      end
    end
  end

  describe 'filtering' do
    context 'when pool has a source_project' do
      let_it_be(:pool_with_source) { create(:pool_repository, shard: dead_shard) }

      before do
        stub_repository_access
      end

      it 'only classifies sourceless pools' do
        run_classification

        pool_ids = csv_data_rows.map { |row| row[0].to_i }
        expect(pool_ids).to include(pool.id)
        expect(pool_ids).not_to include(pool_with_source.id)
      end
    end
  end

  describe 'report' do
    before do
      stub_repository_access
    end

    it 'logs the classification report' do
      run_classification

      expect(logger).to have_received(:info).with(/Classification Report/)
      expect(logger).to have_received(:info).with(/Total: 1/)
    end
  end

  describe 'csv_writer cleanup' do
    it 'closes csv_writer even when error occurs' do
      csv_writer_double = instance_double(Gitlab::PoolRepositories::CsvWriter,
        write_row: nil, flush: nil, close: nil)

      allow(Gitlab::PoolRepositories::CsvWriter).to receive(:new).and_return(csv_writer_double)

      classifier = described_class.new(
        shard_names: ['nfs-file99'],
        logger: logger,
        output_file: output_file
      )

      allow(classifier).to receive(:classify_pools).and_raise(StandardError, 'test')

      expect(csv_writer_double).to receive(:close)
      expect { classifier.run! }.to raise_error(StandardError)
    end
  end

  private

  def stub_repository_access(exists: true, object_pool: nil)
    allow_next_instance_of(Repository) do |repo|
      raw = instance_double(Gitlab::Git::Repository, exists?: exists)
      allow(repo).to receive_messages(raw: raw, object_pool: object_pool)
    end
  end
end
