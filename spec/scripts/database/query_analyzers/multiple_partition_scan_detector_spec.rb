# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'

require_relative '../../../../scripts/database/query_analyzers/multiple_partition_scan_detector'

RSpec.describe Database::QueryAnalyzers::MultiplePartitionScanDetector, feature_category: :database do
  let(:unpruned_plan) { '{"Node Type"=>"Append", "Subplans Removed"=>0}' }
  let(:pruned_plan) { '{"Node Type"=>"Append", "Subplans Removed"=>3}' }

  let(:offending_query) do
    {
      'query' => 'SELECT * FROM p_ci_pipelines WHERE id = $1',
      'plan' => unpruned_plan,
      'fingerprint' => '0000000000000001'
    }
  end

  let(:config) { {} }

  subject(:analyzer) { described_class.new(config) }

  describe '#analyze' do
    it 'flags any p_ci_* table via prefix matching' do
      analyzer.analyze(offending_query)

      expect(analyzer.output['p_ci_pipelines']).to contain_exactly(offending_query)
    end

    it 'extracts the full table token' do
      query = offending_query.merge('query' => 'SELECT * FROM p_ci_build_names WHERE build_id = $1')

      analyzer.analyze(query)

      expect(analyzer.output.keys).to contain_exactly('p_ci_build_names')
    end

    it 'attributes a query touching multiple partitioned tables to each table' do
      query = offending_query.merge(
        'query' => 'SELECT * FROM p_ci_builds JOIN p_ci_build_names USING (build_id, partition_id)'
      )

      analyzer.analyze(query)

      expect(analyzer.output.keys).to contain_exactly('p_ci_builds', 'p_ci_build_names')
    end

    it 'does not flag a query whose plan pruned partitions' do
      analyzer.analyze(offending_query.merge('plan' => pruned_plan))

      expect(analyzer.output).to be_empty
    end

    it 'does not flag when the plan has no Subplans Removed field (absence is not a violation)' do
      analyzer.analyze(offending_query.merge('plan' => '{"Node Type"=>"Index Scan"}'))

      expect(analyzer.output).to be_empty
    end

    it 'does not flag queries that touch no p_ci_* table' do
      analyzer.analyze(offending_query.merge('query' => 'SELECT * FROM ci_runners'))

      expect(analyzer.output).to be_empty
    end

    context 'with a table-existence sweep' do
      it 'does not flag it (a bare existence probe over every table has no partition key to prune)' do
        sweep_query = offending_query.merge(
          'query' => '(SELECT EXISTS( SELECT * FROM p_ci_builds )) UNION ' \
            '(SELECT EXISTS( SELECT * FROM p_ci_pipelines )) UNION ' \
            '(SELECT EXISTS( SELECT * FROM vulnerability_reads ))'
        )

        analyzer.analyze(sweep_query)

        expect(analyzer.output).to be_empty
      end

      it 'excludes the minimum sweep of exactly two bare probes' do
        query = offending_query.merge(
          'query' => '(SELECT EXISTS( SELECT * FROM p_ci_builds )) UNION ' \
            '(SELECT EXISTS( SELECT * FROM p_ci_pipelines ))'
        )

        analyzer.analyze(query)

        expect(analyzer.output).to be_empty
      end

      it 'still flags a single unfiltered existence probe (not a sweep)' do
        query = offending_query.merge('query' => 'SELECT EXISTS( SELECT * FROM p_ci_builds )')

        analyzer.analyze(query)

        expect(analyzer.output.keys).to contain_exactly('p_ci_builds')
      end

      it 'does not treat repeated filtered EXISTS checks as a sweep' do
        query = offending_query.merge(
          'query' => '(SELECT EXISTS( SELECT * FROM p_ci_builds WHERE id = $1 )) UNION ' \
            '(SELECT EXISTS( SELECT * FROM p_ci_pipelines WHERE id = $2 ))'
        )

        analyzer.analyze(query)

        expect(analyzer.output.keys).to contain_exactly('p_ci_builds', 'p_ci_pipelines')
      end
    end

    context 'with a batched deletion sweep' do
      it 'does not flag it (full-table cleanup has to touch every partition)' do
        sweep_query = offending_query.merge(
          'query' => 'DELETE FROM "projects";DELETE FROM "p_ci_builds";' \
            'DELETE FROM "p_ci_job_artifacts";DELETE FROM "vulnerability_reads";'
        )

        analyzer.analyze(sweep_query)

        expect(analyzer.output).to be_empty
      end

      it 'excludes the minimum sweep of exactly two bare deletes' do
        query = offending_query.merge(
          'query' => 'DELETE FROM "p_ci_builds";DELETE FROM "p_ci_pipelines";'
        )

        analyzer.analyze(query)

        expect(analyzer.output).to be_empty
      end

      it 'still flags a single unfiltered delete (not a sweep)' do
        query = offending_query.merge('query' => 'DELETE FROM "p_ci_builds";')

        analyzer.analyze(query)

        expect(analyzer.output.keys).to contain_exactly('p_ci_builds')
      end

      it 'does not treat repeated filtered deletes as a sweep' do
        query = offending_query.merge(
          'query' => 'DELETE FROM "p_ci_builds" WHERE partition_id = $1;' \
            'DELETE FROM "p_ci_pipelines" WHERE partition_id = $2;'
        )

        analyzer.analyze(query)

        expect(analyzer.output.keys).to contain_exactly('p_ci_builds', 'p_ci_pipelines')
      end
    end

    context 'when the fingerprint is in todos (bare string)' do
      let(:config) { { 'todos' => [offending_query['fingerprint']] } }

      it 'ignores the query' do
        analyzer.analyze(offending_query)

        expect(analyzer.output).to be_empty
      end
    end

    context 'when the fingerprint is in todos (hash entry with issue)' do
      let(:config) do
        { 'todos' => [{ 'fingerprint' => offending_query['fingerprint'],
                        'issue' => 'https://example.com/1' }] }
      end

      it 'ignores the query' do
        analyzer.analyze(offending_query)

        expect(analyzer.output).to be_empty
      end
    end

    context 'when the fingerprint is allowed (bare string)' do
      let(:config) { { 'allowed' => [offending_query['fingerprint']] } }

      it 'ignores the query' do
        analyzer.analyze(offending_query)

        expect(analyzer.output).to be_empty
      end
    end

    context 'when the fingerprint is allowed (hash entry with reason/issue)' do
      let(:config) do
        { 'allowed' => [{ 'fingerprint' => offending_query['fingerprint'], 'reason' => 'by design',
                          'issue' => 'https://example.com/1' }] }
      end

      it 'ignores the query' do
        analyzer.analyze(offending_query)

        expect(analyzer.output).to be_empty
      end
    end

    context 'when an allowlist hash entry is missing its fingerprint (e.g. a YAML typo)' do
      let(:config) { { 'allowed' => [{ 'fingerpint' => offending_query['fingerprint'] }] } }

      it 'raises so the misconfiguration is caught early rather than silently ignored' do
        expect { analyzer.analyze(offending_query) }
          .to raise_error(ArgumentError, /missing a 'fingerprint' value/)
      end
    end
  end

  describe '#save!' do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      stub_env('RSPEC_AUTO_EXPLAIN_LOG_PATH', File.join(tmpdir, 'auto_explain.ndjson.gz'))
    end

    after do
      FileUtils.remove_entry(tmpdir)
    end

    def read_gz(name)
      Zlib::GzipReader.open(File.join(tmpdir, name), &:read)
    end

    it 'writes a gzipped ndjson file for a single offending table' do
      analyzer.analyze(offending_query)

      analyzer.save!

      expect(read_gz('p_ci_pipelines_multiple_partition_scans.ndjson.gz'))
        .to include(offending_query['fingerprint'])
    end

    it 'writes a separate file per table when a query touches multiple p_ci_* tables' do
      query = offending_query.merge(
        'query' => 'SELECT * FROM p_ci_builds JOIN p_ci_build_names USING (build_id, partition_id)'
      )

      analyzer.analyze(query)
      analyzer.save!

      %w[p_ci_builds p_ci_build_names].each do |table|
        contents = read_gz("#{table}_multiple_partition_scans.ndjson.gz")
        expect(contents).to include(query['fingerprint'])
      end
    end

    it 'writes nothing when no query offended' do
      analyzer.analyze(offending_query.merge('plan' => pruned_plan))

      analyzer.save!

      expect(Dir.glob(File.join(tmpdir, '*_multiple_partition_scans.ndjson.gz'))).to be_empty
    end
  end
end
