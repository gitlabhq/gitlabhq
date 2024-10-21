# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'fileutils'

require_relative '../../../../tooling/lib/tooling/parallel_rspec_runner'

RSpec.describe Tooling::ParallelRSpecRunner, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- parallel_r_spec_runner_spec.rb is too long
  describe '#run' do
    let(:test_dir) { 'spec' }
    let(:node_tests) { %w[01_spec.rb 03_spec.rb] }
    let(:allocator) { instance_double(Knapsack::Allocator, test_dir: test_dir, node_tests: node_tests) }
    let(:allocator_builder) { instance_double(Knapsack::AllocatorBuilder, allocator: allocator) }

    let(:filter_tests) { [] }
    let(:filter_tests_file) { nil }
    let(:filter_tests_file_path) { nil }

    before do
      allow(Knapsack::AllocatorBuilder).to receive(:new).and_return(allocator_builder)
    end

    after do
      if filter_tests_file.respond_to?(:close)
        filter_tests_file.close
        File.unlink(filter_tests_file)
      end
    end

    subject(:runner) do
      described_class.new(filter_tests_file: filter_tests_file_path, rspec_args: rspec_args)
    end

    shared_examples 'runs node tests' do
      let(:rspec_args) { nil }

      before do
        allow(Knapsack.logger).to receive(:info)
      end

      it 'runs rspec with tests allocated for this node' do
        expect(allocator_builder).to receive(:filter_tests=).with(filter_tests)
        expect_command(%W[bundle exec rspec#{rspec_args} --] + node_tests)

        runner.run
      end
    end

    context 'without filter_tests_file option' do
      subject(:runner) { described_class.new(rspec_args: rspec_args) }

      it_behaves_like 'runs node tests'
    end

    context 'given filter tests file' do
      let(:filter_tests_file) do
        Tempfile.create.tap do |f|
          f.write(filter_tests.join(' '))
          f.rewind
        end
      end

      let(:filter_tests_file_path) { filter_tests_file.path }

      context 'when filter_tests_file is empty' do
        it_behaves_like 'runs node tests'
      end

      context 'when filter_tests_file does not exist' do
        let(:filter_tests_file_path) { 'doesnt_exist' }

        it_behaves_like 'runs node tests'
      end

      context 'when filter_tests_file is not empty' do
        let(:filter_tests) { %w[01_spec.rb 02_spec.rb 03_spec.rb] }

        it_behaves_like 'runs node tests'
      end
    end

    context 'with rspec args' do
      let(:rspec_args) { ' --seed 123' }

      it_behaves_like 'runs node tests'
    end

    # rubocop:disable Gitlab/Json -- standard JSON is sufficient
    context 'when KNAPSACK_RSPEC_SUITE_REPORT_PATH set' do
      let(:rspec_args)              { nil }
      let(:master_report_file_name) { 'master-report1.json' }
      let(:master_report) do
        {
          "01_spec.rb" => 65,
          "02_spec.rb" => 60
        }
      end

      let(:master_report_file) do
        Tempfile.open(master_report_file_name) do |f|
          f.write(JSON.dump(master_report))
          f
        end
      end

      let(:expected_report_file_path) do
        "#{File.dirname(master_report_file.path)}/node_specs_expected_duration.json"
      end

      let(:expected_report_content) { JSON.dump({ "01_spec.rb" => 65 }) }

      before do
        stub_env('KNAPSACK_RSPEC_SUITE_REPORT_PATH', master_report_file.path)
        allow(allocator_builder).to receive(:filter_tests=).with(filter_tests)
        allow(runner).to receive(:exec)
      end

      after do
        master_report_file.close
        master_report_file.unlink
      end

      context 'when GITLAB_CI env var is not set' do
        before do
          stub_env('GITLAB_CI', nil)
        end

        it 'does not parse expected rspec report' do
          expected_output = <<~MARKDOWN.chomp
            Running command: bundle exec rspec -- 01_spec.rb 03_spec.rb

          MARKDOWN

          expect(File).not_to receive(:write).with(expected_report_file_path, expected_report_content)

          expect { runner.run }.to output(expected_output).to_stdout
        end
      end

      context 'with GITLAB_CI env var set to true' do
        before do
          stub_env('GITLAB_CI', true)
        end

        it 'parses expected rspec report' do
          expected_output = <<~MARKDOWN.chomp
            Parsing expected rspec suite duration...
            03_spec.rb not found in master report
            RSpec suite is expected to take 1 minute 5 seconds.
            Expected duration for tests:

            {
              "01_spec.rb": 65
            }

            Running command: bundle exec rspec -- 01_spec.rb 03_spec.rb

          MARKDOWN

          expect(File).to receive(:write).with(expected_report_file_path, expected_report_content)

          expect { runner.run }.to output(expected_output).to_stdout
        end
      end
    end
    # rubocop:enable Gitlab/Json

    def expect_command(cmd)
      expect(runner).to receive(:exec).with(*cmd)
    end
  end
end
