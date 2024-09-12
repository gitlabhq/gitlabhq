# frozen_string_literal: true

RSpec.shared_examples_for 'a ci_finished_pipelines aggregation model' do |table_name|
  let(:instance) { described_class.new }

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
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT "#{table_name}"."status" FROM "#{table_name}"
        WHERE "#{table_name}"."path" = '#{path}'
        AND "#{table_name}"."status" IN ('failed', 'success')
        GROUP BY "#{table_name}"."status"
      SQL

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end
end
