# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::PoolRepositories::CsvWriter, feature_category: :source_code_management do
  let(:temp_file) { Tempfile.new('orphaned_pools.csv') }
  let(:csv_writer) { described_class.new(temp_file.path) }
  let(:record) do
    {
      pool_id: 1,
      disk_path: '@pools/test',
      relative_path: '@pools/test.git',
      source_project_id: 123,
      state: 'ready',
      reason_codes: 'test_reason',
      reasons: 'Test reason description',
      member_projects_count: 5,
      shard_name: 'default'
    }
  end

  after do
    csv_writer.close
    temp_file.close!
  end

  describe '#write_row' do
    context 'when writing a single row' do
      it 'writes a properly formatted CSV row with all fields' do
        csv_writer.write_row(record)
        csv_writer.close

        rows = CSV.read(temp_file.path)
        expect(rows.size).to eq(2)
        expect(rows[1]).to eq(
          ['1', '@pools/test', '@pools/test.git', '123', 'ready', 'test_reason', 'Test reason description', '5',
            'default']
        )
      end
    end

    context 'when writing multiple rows' do
      let(:second_record) do
        {
          pool_id: 2,
          disk_path: '@pools/other',
          relative_path: '@pools/other.git',
          source_project_id: 456,
          state: 'obsolete',
          reason_codes: 'pool_in_obsolete_state',
          reasons: 'Pool marked as obsolete',
          member_projects_count: 0,
          shard_name: 'default'
        }
      end

      it 'writes all rows in order' do
        csv_writer.write_row(record)
        csv_writer.write_row(second_record)
        csv_writer.close

        rows = CSV.read(temp_file.path)
        expect(rows.size).to eq(3)
        expect(rows[1]).to include('@pools/test')
        expect(rows[2]).to include('@pools/other')
      end
    end
  end

  describe '#flush' do
    it 'makes written rows readable from the file before close' do
      csv_writer.write_row(record)
      csv_writer.flush

      rows = CSV.read(temp_file.path)
      expect(rows.size).to eq(2)
      expect(rows[1]).to include('@pools/test')
    end

    it 'does not raise after close' do
      csv_writer.close

      expect { csv_writer.flush }.not_to raise_error
    end
  end

  describe '#close' do
    it 'does not raise when called' do
      expect { csv_writer.close }.not_to raise_error
    end
  end

  describe 'initialization' do
    it 'writes CSV headers as the first line' do
      csv_writer.close

      rows = CSV.read(temp_file.path)
      expect(rows.size).to eq(1)
      expect(rows[0]).to eq(described_class::COLUMNS.map { |c| c[:header] })
    end

    context 'with custom columns' do
      let(:columns) do
        [
          { key: :pool_id, header: 'Pool ID' },
          { key: :shard_name, header: 'Shard Name' }
        ]
      end

      let(:csv_writer) { described_class.new(temp_file.path, columns: columns) }

      it 'writes only the given columns' do
        csv_writer.write_row(record)
        csv_writer.close

        rows = CSV.read(temp_file.path)
        expect(rows[0]).to eq(['Pool ID', 'Shard Name'])
        expect(rows[1]).to eq(%w[1 default])
      end
    end
  end
end
