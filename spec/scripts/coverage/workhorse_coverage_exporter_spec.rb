# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require_relative '../../../scripts/coverage/workhorse_coverage_exporter'

RSpec.describe WorkhorseCoverageExporter, feature_category: :tooling do
  let(:temp_dir) { Dir.mktmpdir }
  let(:env) do
    {
      'CLICKHOUSE_URL' => 'http://localhost:8123',
      'CLICKHOUSE_DATABASE' => 'test_db',
      'CLICKHOUSE_USERNAME' => 'test_user'
    }
  end

  let(:exporter) { described_class.new(env: env) }

  before do
    allow(exporter).to receive(:puts)

    stub_const('WorkhorseCoverageExporter::COVERAGE_REPORT', File.join(temp_dir, 'coverage.lcov'))
    stub_const('WorkhorseCoverageExporter::TEST_REPORT', File.join(temp_dir, 'workhorse-tests.json'))
    stub_const('WorkhorseCoverageExporter::TEST_MAP', File.join(temp_dir, 'workhorse-source-to-test.json'))
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_coverage_report
    File.write(File.join(temp_dir, 'coverage.lcov'), 'SF:workhorse/main.go')
  end

  def create_test_report
    File.write(File.join(temp_dir, 'workhorse-tests.json'), '{}')
  end

  def create_test_map
    File.write(File.join(temp_dir, 'workhorse-source-to-test.json'), '{}')
  end

  describe '#run' do
    context 'when all artifacts are present' do
      before do
        create_coverage_report
        create_test_report
        create_test_map
      end

      it 'exports to ClickHouse and returns true' do
        allow(exporter).to receive(:system).and_return(true)

        result = exporter.run

        expect(result).to be true
        expect(exporter).to have_received(:system).with(
          'bundle', 'exec', 'test-coverage',
          '--test-reports', anything,
          '--coverage-report', anything,
          '--test-map', anything,
          '--clickhouse-url', 'http://localhost:8123',
          '--clickhouse-database', 'test_db',
          '--clickhouse-shared-database', '',
          '--clickhouse-username', 'test_user',
          '--responsibility-patterns', '.gitlab/coverage/responsibility_patterns.yml'
        )
      end
    end

    context 'when coverage report is missing' do
      before do
        create_test_report
        create_test_map
      end

      it 'skips export and returns true' do
        result = exporter.run

        expect(result).to be true
        expect(exporter).to have_received(:puts).with('Skipping export: coverage report not found')
      end
    end

    context 'when test report is missing' do
      before do
        create_coverage_report
        create_test_map
      end

      it 'skips export and returns true' do
        result = exporter.run

        expect(result).to be true
        expect(exporter).to have_received(:puts).with('Skipping export: test report not found')
      end
    end

    context 'when test map is missing' do
      before do
        create_coverage_report
        create_test_report
      end

      it 'skips export and returns true' do
        result = exporter.run

        expect(result).to be true
        expect(exporter).to have_received(:puts).with('Skipping export: test mapping not found')
      end
    end
  end

  describe '#print_summary' do
    context 'when all artifacts exist' do
      before do
        create_coverage_report
        create_test_report
        create_test_map
      end

      it 'prints status with checkmarks' do
        allow(exporter).to receive(:system).and_return(true)
        exporter.run

        expect(exporter).to have_received(:puts).with(/\[✓\] Coverage report/)
        expect(exporter).to have_received(:puts).with(/\[✓\] Test report/)
        expect(exporter).to have_received(:puts).with(/\[✓\] Test mapping/)
      end
    end

    context 'when artifacts are missing' do
      it 'prints status with X marks' do
        exporter.run

        expect(exporter).to have_received(:puts).with(/\[✗\] Coverage report: NOT FOUND/)
        expect(exporter).to have_received(:puts).with(/\[✗\] Test report: NOT FOUND/)
        expect(exporter).to have_received(:puts).with(/\[✗\] Test mapping: NOT FOUND/)
      end
    end
  end
end
