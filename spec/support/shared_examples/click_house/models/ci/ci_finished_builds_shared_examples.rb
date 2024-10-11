# frozen_string_literal: true

RSpec.shared_examples_for 'a ci_finished_pipelines aggregation model' do |table_name|
  let(:instance) { described_class.new }
  let(:ref) { 'master' }
  let(:source) { 'api' }

  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:path) { project.reload.project_namespace.traversal_path }

  specify { expect(path).to match(%r{\A(\d+/){3}\z}) }

  describe '#for_project' do
    subject(:result_sql) { instance.for_project(project).to_sql }

    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "#{table_name}"
        WHERE "#{table_name}"."path" = '#{path}'
      SQL

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#for_ref' do
    subject(:result_sql) { instance.for_ref(ref).to_sql }

    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "#{table_name}"
        WHERE "#{table_name}"."ref" = '#{ref}'
      SQL

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#for_source' do
    subject(:result_sql) { instance.for_source(source).to_sql }

    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "#{table_name}"
        WHERE "#{table_name}"."source" = '#{source}'
      SQL

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#within_dates' do
    let(:from_time) { 1.hour.ago }
    let(:to_time) { Time.current }

    subject(:result_sql) { instance.within_dates(from_time, to_time).to_sql }

    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "#{table_name}"
        WHERE "#{table_name}"."started_at_bucket" >= toDateTime64('#{from_time.utc.strftime('%Y-%m-%d %H:%M:%S')}', 6, 'UTC')
        AND "#{table_name}"."started_at_bucket" < toDateTime64('#{to_time.utc.strftime('%Y-%m-%d %H:%M:%S')}', 6, 'UTC')
      SQL

      expect(result_sql.strip).to eq(expected_sql.strip)
    end

    context 'when only from_date is passed' do
      let(:from_time) { 1.hour.ago }
      let(:to_time) { nil }

      it 'builds the correct SQL' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "#{table_name}"
          WHERE "#{table_name}"."started_at_bucket" >= toDateTime64('#{from_time.utc.strftime('%Y-%m-%d %H:%M:%S')}', 6, 'UTC')
        SQL

        expect(result_sql.strip).to eq(expected_sql.strip)
      end
    end

    context 'when only to_date is passed' do
      let(:from_time) { nil }
      let(:to_time) { Time.current }

      it 'builds the correct SQL' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT * FROM "#{table_name}"
          WHERE "#{table_name}"."started_at_bucket" < toDateTime64('#{to_time.utc.strftime('%Y-%m-%d %H:%M:%S')}', 6, 'UTC')
        SQL

        expect(result_sql.strip).to eq(expected_sql.strip)
      end
    end
  end

  describe '#by_status' do
    subject(:result_sql) { instance.by_status(%i[failed success]).to_sql }

    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "#{table_name}"
        WHERE "#{table_name}"."status" IN ('failed', 'success')
      SQL

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#group_by_status' do
    subject(:result_sql) { instance.select(:status).group_by_status.to_sql }

    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT "#{table_name}"."status"
        FROM "#{table_name}"
        GROUP BY "#{table_name}"."status"
      SQL

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#count_pipelines_function' do
    subject(:result_sql) { instance.select(:status, instance.count_pipelines_function).to_sql }

    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT "#{table_name}"."status", countMerge("#{table_name}"."count_pipelines")
        FROM "#{table_name}"
      SQL

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#duration_quantile_function' do
    subject(:result_sql) { instance.select(instance.duration_quantile_function(quantile)).to_sql }

    context 'when quantile is 50' do
      let(:quantile) { 50 }

      it 'builds the correct SQL' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT quantileMerge(0.5)("#{table_name}"."duration_quantile") AS p50
          FROM "#{table_name}"
        SQL

        expect(result_sql.strip).to eq(expected_sql.strip)
      end
    end

    context 'when quantile is 99' do
      let(:quantile) { 99 }

      it 'builds the correct SQL' do
        expected_sql = <<~SQL.lines(chomp: true).join(' ')
          SELECT quantileMerge(0.99)("#{table_name}"."duration_quantile") AS p99
          FROM "#{table_name}"
        SQL

        expect(result_sql.strip).to eq(expected_sql.strip)
      end
    end
  end

  describe 'class methods' do
    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    describe '.for_project' do
      it 'calls the corresponding instance method' do
        expect(instance).to receive(:for_project).with(project)

        described_class.for_project(project)
      end
    end

    describe '.by_status' do
      it 'calls the corresponding instance method' do
        expect(instance).to receive(:by_status).with(:success)

        described_class.by_status(:success)
      end
    end

    describe '.group_by_status' do
      it 'calls the corresponding instance method' do
        expect(instance).to receive(:group_by_status)

        described_class.group_by_status
      end
    end
  end

  describe 'method chaining' do
    subject(:result_sql) do
      instance.for_project(project).select(:status).by_status(%i[failed success]).group_by_status.to_sql
    end

    it 'builds the correct SQL with chained methods' do
      from_time = 1.hour.ago
      to_time = Time.current

      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT "#{table_name}"."status" FROM "#{table_name}"
        WHERE "#{table_name}"."path" = '#{path}'
        AND "#{table_name}"."started_at_bucket" >= toDateTime64('#{from_time.utc.strftime('%Y-%m-%d %H:%M:%S')}', 6, 'UTC')
        AND "#{table_name}"."started_at_bucket" < toDateTime64('#{to_time.utc.strftime('%Y-%m-%d %H:%M:%S')}', 6, 'UTC')
        AND "#{table_name}"."status" IN ('failed', 'success')
        GROUP BY "#{table_name}"."status"
      SQL

      result_sql = instance
        .for_project(project)
        .select(:status)
        .within_dates(from_time, to_time)
        .by_status(%i[failed success])
        .group_by_status.to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end
end
