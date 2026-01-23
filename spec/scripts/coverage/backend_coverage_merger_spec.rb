# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require_relative '../../../scripts/coverage/merge_backend_coverage'

RSpec.describe BackendCoverageMerger, feature_category: :tooling do
  let(:temp_dir) { Dir.mktmpdir }
  let(:rspec_lcov_path) { File.join(temp_dir, 'rspec.lcov') }
  let(:e2e_coverband_glob) { File.join(temp_dir, 'coverband-*.json') }
  let(:output_dir) { File.join(temp_dir, 'coverage-backend') }
  let(:output_file) { File.join(output_dir, 'coverage.lcov') }

  subject(:merger) { described_class.new(rspec_lcov: rspec_lcov_path, e2e_coverband_glob: e2e_coverband_glob) }

  before do
    allow(merger).to receive(:puts)
    allow(merger).to receive(:warn)
    stub_const("#{described_class}::OUTPUT_DIR", output_dir)
    stub_const("#{described_class}::OUTPUT_FILE", output_file)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#merge' do
    context 'when no coverage data exists' do
      it 'exits with error' do
        expect(merger).to receive(:warn).with('ERROR: No coverage data found')

        expect { merger.merge }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'when only RSpec coverage exists' do
      let(:rspec_lcov_content) do
        <<~LCOV
          TN:
          SF:app/models/user.rb
          DA:1,5
          DA:2,3
          DA:3,0
          LF:3
          LH:2
          end_of_record
        LCOV
      end

      before do
        File.write(rspec_lcov_path, rspec_lcov_content)
      end

      it 'creates output with RSpec coverage only' do
        merger.merge

        output_file = File.join(temp_dir, 'coverage-backend', 'coverage.lcov')
        expect(File.exist?(output_file)).to be true

        content = File.read(output_file)
        expect(content).to include('SF:app/models/user.rb')
        expect(content).to include('DA:1,5')
        expect(content).to include('DA:2,3')
        expect(content).to include('DA:3,0')
      end
    end

    context 'when only E2E Coverband coverage exists' do
      let(:coverband_data) do
        {
          "spec/example_spec.rb" => {
            "app/models/user.rb" => { "1" => 2, "2" => 1 }
          }
        }
      end

      it 'creates output with E2E coverage only' do
        # Write files before creating merger so glob picks them up
        File.write(File.join(temp_dir, 'coverband-1.json'), coverband_data.to_json)
        merger = described_class.new(rspec_lcov: rspec_lcov_path, e2e_coverband_glob: e2e_coverband_glob)
        allow(merger).to receive(:puts)
        allow(merger).to receive(:warn)

        merger.merge

        expect(File.exist?(output_file)).to be true

        content = File.read(output_file)
        expect(content).to include('SF:app/models/user.rb')
        expect(content).to include('DA:1,2')
        expect(content).to include('DA:2,1')
      end
    end

    context 'when both RSpec and E2E coverage exist' do
      let(:rspec_lcov_content) do
        <<~LCOV
          TN:
          SF:app/models/user.rb
          DA:1,5
          DA:2,3
          LF:2
          LH:2
          end_of_record
          TN:
          SF:app/models/project.rb
          DA:1,10
          LF:1
          LH:1
          end_of_record
        LCOV
      end

      let(:coverband_data) do
        {
          "spec/example_spec.rb" => {
            "app/models/user.rb" => { "1" => 2, "3" => 1 },
            "app/controllers/application_controller.rb" => { "1" => 5 }
          }
        }
      end

      it 'merges coverage data from both sources' do
        # Write files before creating merger so glob picks them up
        File.write(rspec_lcov_path, rspec_lcov_content)
        File.write(File.join(temp_dir, 'coverband-1.json'), coverband_data.to_json)
        merger = described_class.new(rspec_lcov: rspec_lcov_path, e2e_coverband_glob: e2e_coverband_glob)
        allow(merger).to receive(:puts)
        allow(merger).to receive(:warn)

        merger.merge

        content = File.read(output_file)

        # user.rb line 1 should have 5 (RSpec) + 2 (E2E) = 7 hits
        expect(content).to match(%r{SF:app/models/user\.rb.*DA:1,7}m)
        # user.rb line 2 should have 3 hits (RSpec only)
        expect(content).to match(%r{SF:app/models/user\.rb.*DA:2,3}m)
        # user.rb line 3 should have 1 hit (E2E only)
        expect(content).to match(%r{SF:app/models/user\.rb.*DA:3,1}m)
        # project.rb should have 10 hits (RSpec only)
        expect(content).to include('SF:app/models/project.rb')
        expect(content).to match(%r{SF:app/models/project\.rb.*DA:1,10}m)
        # application_controller.rb should have 5 hits (E2E only)
        expect(content).to include('SF:app/controllers/application_controller.rb')
      end
    end
  end

  describe '#parse_lcov (private)' do
    let(:lcov_content) do
      <<~LCOV
        TN:
        SF:app/models/user.rb
        DA:1,5
        DA:2,3
        DA:10,0
        LF:3
        LH:2
        end_of_record
        TN:
        SF:app/models/project.rb
        DA:1,10
        LF:1
        LH:1
        end_of_record
      LCOV
    end

    before do
      File.write(rspec_lcov_path, lcov_content)
    end

    it 'parses LCOV file into coverage hash' do
      coverage = {}
      merger.send(:parse_lcov, rspec_lcov_path, coverage)

      expect(coverage['app/models/user.rb'][:lines]).to eq({ 1 => 5, 2 => 3, 10 => 0 })
      expect(coverage['app/models/project.rb'][:lines]).to eq({ 1 => 10 })
    end

    it 'merges with existing coverage data' do
      coverage = {
        'app/models/user.rb' => { lines: { 1 => 2, 3 => 1 }, branches: [], branch_stats: { found: 0, hit: 0 } }
      }
      merger.send(:parse_lcov, rspec_lcov_path, coverage)

      # Line 1 should be merged: 2 + 5 = 7
      expect(coverage['app/models/user.rb'][:lines][1]).to eq(7)
      # Line 2 should be new from LCOV
      expect(coverage['app/models/user.rb'][:lines][2]).to eq(3)
      # Line 3 should be preserved from existing
      expect(coverage['app/models/user.rb'][:lines][3]).to eq(1)
    end

    context 'with branch coverage data' do
      let(:lcov_content) do
        <<~LCOV
          TN:
          SF:app/models/user.rb
          DA:1,5
          DA:2,3
          BRDA:1,0,1,3
          BRDA:1,0,2,2
          BRF:2
          BRH:2
          end_of_record
        LCOV
      end

      it 'parses branch coverage data' do
        coverage = {}
        merger.send(:parse_lcov, rspec_lcov_path, coverage)

        expect(coverage['app/models/user.rb'][:branches]).to match_array(['BRDA:1,0,1,3', 'BRDA:1,0,2,2'])
        expect(coverage['app/models/user.rb'][:branch_stats]).to eq({ found: 2, hit: 2 })
      end
    end
  end

  describe '#parse_coverband_json (private)' do
    context 'with hash format coverage data' do
      let(:coverband_data) do
        {
          "spec_location_1" => {
            "app/models/user.rb" => { "1" => "5", "2" => "10" },
            "app/controllers/application_controller.rb" => { "1" => "3" }
          }
        }
      end

      let(:coverband_path) { File.join(temp_dir, 'coverband.json') }

      before do
        File.write(coverband_path, coverband_data.to_json)
      end

      it 'parses Coverband JSON into coverage hash' do
        coverage = {}
        merger.send(:parse_coverband_json, coverband_path, coverage)

        expect(coverage['app/models/user.rb'][:lines]).to eq({ 1 => 5, 2 => 10 })
        expect(coverage['app/controllers/application_controller.rb'][:lines]).to eq({ 1 => 3 })
      end
    end

    context 'with array format coverage data' do
      let(:coverband_data) do
        {
          "spec_location" => {
            "app/models/user.rb" => [5, 10, nil, 2]
          }
        }
      end

      let(:coverband_path) { File.join(temp_dir, 'coverband.json') }

      before do
        File.write(coverband_path, coverband_data.to_json)
      end

      it 'converts array indices to 1-based line numbers' do
        coverage = {}
        merger.send(:parse_coverband_json, coverband_path, coverage)

        expect(coverage['app/models/user.rb'][:lines][1]).to eq(5)
        expect(coverage['app/models/user.rb'][:lines][2]).to eq(10)
        expect(coverage['app/models/user.rb'][:lines][3]).to be_nil
        expect(coverage['app/models/user.rb'][:lines][4]).to eq(2)
      end
    end

    context 'with leading ./ in file paths' do
      let(:coverband_data) do
        {
          "spec_location" => {
            "./app/models/user.rb" => { "1" => "5" }
          }
        }
      end

      let(:coverband_path) { File.join(temp_dir, 'coverband.json') }

      before do
        File.write(coverband_path, coverband_data.to_json)
      end

      it 'normalizes paths by removing leading ./' do
        coverage = {}
        merger.send(:parse_coverband_json, coverband_path, coverage)

        expect(coverage['app/models/user.rb'][:lines]).to eq({ 1 => 5 })
        expect(coverage['./app/models/user.rb']).to be_nil
      end
    end

    context 'with absolute paths from Coverband' do
      let(:coverband_data) do
        {
          "spec_location" => {
            "/builds/gitlab-org/gitlab/app/models/user.rb" => { "1" => "5" },
            "/home/gdk/gitlab-development-kit/gitlab/lib/api/api.rb" => { "1" => "3" }
          }
        }
      end

      let(:coverband_path) { File.join(temp_dir, 'coverband.json') }

      before do
        File.write(coverband_path, coverband_data.to_json)
      end

      it 'normalizes absolute paths to relative paths' do
        coverage = {}
        merger.send(:parse_coverband_json, coverband_path, coverage)

        expect(coverage['app/models/user.rb'][:lines]).to eq({ 1 => 5 })
        expect(coverage['lib/api/api.rb'][:lines]).to eq({ 1 => 3 })
        # Should not have absolute paths
        expect(coverage['/builds/gitlab-org/gitlab/app/models/user.rb']).to be_nil
        expect(coverage['/home/gdk/gitlab-development-kit/gitlab/lib/api/api.rb']).to be_nil
      end
    end
  end

  describe '#write_lcov (private)' do
    let(:coverage_data) do
      {
        'app/models/user.rb' => {
          lines: { 1 => 5, 2 => 10, 3 => 0 },
          branches: [],
          branch_stats: { found: 0, hit: 0 }
        },
        'app/controllers/application_controller.rb' => {
          lines: { 1 => 3 },
          branches: [],
          branch_stats: { found: 0, hit: 0 }
        }
      }
    end

    it 'writes valid LCOV format' do
      merger.send(:write_lcov, coverage_data)

      output_file = File.join(temp_dir, 'coverage-backend', 'coverage.lcov')
      content = File.read(output_file)

      expect(content).to include('TN:')
      expect(content).to include('SF:app/models/user.rb')
      expect(content).to include('DA:1,5')
      expect(content).to include('DA:2,10')
      expect(content).to include('DA:3,0')
      expect(content).to include('LF:3')
      expect(content).to include('LH:2')
      expect(content).to include('end_of_record')
    end

    it 'prints coverage summary' do
      expect(merger).to receive(:puts).with('')
      expect(merger).to receive(:puts).with('Coverage summary:')
      expect(merger).to receive(:puts).with('  Files: 2')
      expect(merger).to receive(:puts).with(%r{Lines: 3/4})
      expect(merger).to receive(:puts).with(%r{Branches: 0/0})

      merger.send(:write_lcov, coverage_data)
    end

    context 'with branch coverage data' do
      let(:coverage_data) do
        {
          'app/models/user.rb' => {
            lines: { 1 => 5, 2 => 10 },
            branches: ['BRDA:1,0,1,3', 'BRDA:1,0,2,2'],
            branch_stats: { found: 2, hit: 2 }
          }
        }
      end

      it 'writes branch coverage data to LCOV output' do
        merger.send(:write_lcov, coverage_data)

        output_file = File.join(temp_dir, 'coverage-backend', 'coverage.lcov')
        content = File.read(output_file)

        expect(content).to include('BRDA:1,0,1,3')
        expect(content).to include('BRDA:1,0,2,2')
        expect(content).to include('BRF:2')
        expect(content).to include('BRH:2')
      end

      it 'prints branch coverage in summary' do
        expect(merger).to receive(:puts).with('')
        expect(merger).to receive(:puts).with('Coverage summary:')
        expect(merger).to receive(:puts).with('  Files: 1')
        expect(merger).to receive(:puts).with(%r{Lines: 2/2})
        expect(merger).to receive(:puts).with('  Branches: 2/2 (100.0%)')

        merger.send(:write_lcov, coverage_data)
      end
    end
  end
end
