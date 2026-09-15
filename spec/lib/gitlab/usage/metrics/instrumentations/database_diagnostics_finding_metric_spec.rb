# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::DatabaseDiagnosticsFindingMetric,
  feature_category: :database do
  def metric(check:, finding_code:)
    described_class.new(time_frame: 'none', options: { check: check, finding_code: finding_code })
  end

  describe '#value' do
    let(:check_class) { Gitlab::Database::Diagnostics::Checks::AutovacuumSettings }
    let(:findings) { [{ code: 'autovacuum_disabled' }] }

    before do
      allow(check_class).to receive(:new).and_return(instance_double(check_class, execute: { findings: findings }))
    end

    it_behaves_like 'a correct instrumented metric value',
      { time_frame: 'none', options: { check: 'autovacuum_settings', finding_code: 'autovacuum_disabled' } } do
      let(:expected_value) { true }
    end

    it 'is false when the check does not report the requested code' do
      expect(metric(check: 'autovacuum_settings', finding_code: 'autovacuum_max_workers_low').value).to be(false)
    end

    it 'runs the check against the main database primary' do
      connection = Gitlab::Database.database_base_models[Gitlab::Database::MAIN_DATABASE_NAME].connection
      session = instance_double(Gitlab::Database::LoadBalancing::Session)

      allow(Gitlab::Database::LoadBalancing::SessionMap).to receive(:current)
        .with(connection.load_balancer).and_return(session)
      allow(session).to receive(:use_primary).and_yield

      expect(check_class).to receive(:new).with(connection)

      metric(check: 'autovacuum_settings', finding_code: 'autovacuum_disabled').value
    end

    context 'when the check fails' do
      before do
        allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(false)
        allow(check_class).to receive(:new).and_raise(ActiveRecord::StatementInvalid)
      end

      # The fallback must stay distinct from false, so a failed read is not
      # counted as an instance with no finding.
      it 'reports the fallback instead of false' do
        expect(metric(check: 'autovacuum_settings', finding_code: 'autovacuum_disabled').value)
          .to eq(described_class::FALLBACK)
      end
    end
  end

  describe 'the check option' do
    it 'rejects a check that does not exist' do
      expect { metric(check: 'not_a_check', finding_code: 'autovacuum_disabled') }
        .to raise_error(ArgumentError, "option 'check' must be one of: autovacuum_settings, search_path")
    end
  end

  # Codes name the problem, not the setting. Pinning every definition to the codes
  # its check emits means a rename in a check cannot silently turn a metric into a
  # permanent false.
  describe 'metric definitions' do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

    def defined_finding_codes(check)
      Gitlab::Usage::MetricDefinition.all
        .map(&:raw_attributes)
        .select { |attributes| attributes[:instrumentation_class] == 'DatabaseDiagnosticsFindingMetric' }
        .map { |attributes| attributes[:options] }
        .select { |options| options[:check] == check }
        .pluck(:finding_code)
    end

    def emitted_finding_codes(check)
      described_class::CHECKS.fetch(check).new(connection).execute[:findings].pluck(:code)
    end

    context 'for autovacuum_settings' do
      # Values that trip every heuristic at once.
      let(:settings_rows) do
        {
          'autovacuum' => 'off',
          'autovacuum_max_workers' => '1',
          'autovacuum_vacuum_cost_delay' => '0',
          'autovacuum_vacuum_cost_limit' => '-1',
          'vacuum_cost_limit' => '200',
          'autovacuum_work_mem' => '-1'
        }.map { |name, setting| { 'name' => name, 'setting' => setting, 'unit' => nil } }
      end

      before do
        allow(connection).to receive(:quote) { |value| "'#{value}'" }
        allow(connection).to receive(:select_all).and_return(settings_rows)
      end

      it 'has one definition per code the check emits' do
        expect(defined_finding_codes('autovacuum_settings'))
          .to match_array(emitted_finding_codes('autovacuum_settings'))
      end
    end

    context 'for search_path' do
      let(:check_class) { Gitlab::Database::Diagnostics::Checks::SchemaResolution }

      # A layout that trips every heuristic at once: a partition schema in the search
      # path, GitLab tables in both "$user" and public, and more in a schema outside it.
      let(:search_path) { '"$user", public, gitlab_partitions_dynamic' }

      let(:schema_rows) do
        %w[public gitlab legacy gitlab_partitions_dynamic].map do |name|
          { 'name' => name, 'is_current' => name == 'public', 'owner' => 'gitlab', 'has_tables' => true }
        end
      end

      let(:schema_table_rows) do
        [
          { 'schema_name' => 'public', 'table_name' => 'projects' },
          { 'schema_name' => 'gitlab', 'table_name' => 'namespaces' },
          { 'schema_name' => 'legacy', 'table_name' => 'issues' }
        ]
      end

      before do
        allow(connection).to receive(:select_value).with('SELECT current_user').and_return('gitlab')
        allow(connection).to receive(:select_value).with('SHOW search_path').and_return(search_path)
        allow(connection).to receive(:select_all).with(check_class::SCHEMAS_SQL).and_return(schema_rows)
        allow(connection).to receive(:select_all).with(check_class::SCHEMA_TABLES_SQL).and_return(schema_table_rows)
      end

      it 'has one definition per code the check emits' do
        expect(defined_finding_codes('search_path')).to match_array(emitted_finding_codes('search_path'))
      end
    end
  end
end
