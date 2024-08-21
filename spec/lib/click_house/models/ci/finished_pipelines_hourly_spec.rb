# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Models::Ci::FinishedPipelinesHourly, feature_category: :fleet_visibility do
  let(:instance) { described_class.new }

  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:path) { project.reload.project_namespace.traversal_path }

  specify { expect(path).to match(%r{\A(\d+/){3}\z}) }

  describe '#for_project' do
    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "ci_finished_pipelines_hourly"
        WHERE "ci_finished_pipelines_hourly"."path" = '#{path}'
      SQL

      result_sql = instance.for_project(project).to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#by_status' do
    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT * FROM "ci_finished_pipelines_hourly"
        WHERE "ci_finished_pipelines_hourly"."status" IN ('failed', 'success')
      SQL

      result_sql = instance.by_status(%i[failed success]).to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#group_by_status' do
    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT "ci_finished_pipelines_hourly"."status"
        FROM "ci_finished_pipelines_hourly"
        GROUP BY "ci_finished_pipelines_hourly"."status"
      SQL

      result_sql = instance.select(:status).group_by_status.to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end

  describe '#count_pipelines_function' do
    it 'builds the correct SQL' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT "ci_finished_pipelines_hourly"."status", countMerge("ci_finished_pipelines_hourly"."count_pipelines")
        FROM "ci_finished_pipelines_hourly"
      SQL

      result_sql = instance.select(:status, instance.count_pipelines_function).to_sql

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
    it 'builds the correct SQL with chained methods' do
      expected_sql = <<~SQL.lines(chomp: true).join(' ')
        SELECT "ci_finished_pipelines_hourly"."status" FROM "ci_finished_pipelines_hourly"
        WHERE "ci_finished_pipelines_hourly"."path" = '#{path}'
        AND "ci_finished_pipelines_hourly"."status" IN ('failed', 'success')
        GROUP BY "ci_finished_pipelines_hourly"."status"
      SQL

      result_sql = instance.for_project(project).select(:status).by_status(%i[failed success]).group_by_status.to_sql

      expect(result_sql.strip).to eq(expected_sql.strip)
    end
  end
end
