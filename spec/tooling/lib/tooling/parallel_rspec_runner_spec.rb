# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/parallel_rspec_runner'

RSpec.describe Tooling::ParallelRSpecRunner do # rubocop:disable RSpec/FilePath
  describe '#run' do
    let(:allocator) { instance_double(Knapsack::Allocator) }
    let(:rspec_args) { '--seed 123' }
    let(:filter_tests_file) { 'tests.txt' }
    let(:node_tests) { %w[01_spec.rb 03_spec.rb 05_spec.rb] }
    let(:filter_tests) { '01_spec.rb 02_spec.rb 03_spec.rb' }
    let(:test_dir) { 'spec' }

    before do
      allow(Knapsack.logger).to receive(:info)
      allow(allocator).to receive(:node_tests).and_return(node_tests)
      allow(allocator).to receive(:test_dir).and_return(test_dir)
      allow(File).to receive(:exist?).with(filter_tests_file).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(filter_tests_file).and_return(filter_tests)
      allow(subject).to receive(:exec)
    end

    subject { described_class.new(allocator: allocator, filter_tests_file: filter_tests_file, rspec_args: rspec_args) }

    shared_examples 'runs node tests' do
      it 'runs rspec with tests allocated for this node' do
        expect_command(%w[bundle exec rspec --seed 123 --default-path spec -- 01_spec.rb 03_spec.rb 05_spec.rb])

        subject.run
      end
    end

    context 'given filter tests' do
      it 'reads filter tests file for list of tests' do
        expect(File).to receive(:read).with(filter_tests_file)

        subject.run
      end

      it 'runs rspec filter tests that are allocated for this node' do
        expect_command(%w[bundle exec rspec --seed 123 --default-path spec -- 01_spec.rb 03_spec.rb])

        subject.run
      end

      context 'when there is no intersect between allocated tests and filtered tests' do
        let(:filter_tests) { '99_spec.rb' }

        it 'does not run rspec' do
          expect(subject).not_to receive(:exec)

          subject.run
        end
      end
    end

    context 'with empty filter tests file' do
      let(:filter_tests) { '' }

      it_behaves_like 'runs node tests'
    end

    context 'without filter_tests_file option' do
      let(:filter_tests_file) { nil }

      it_behaves_like 'runs node tests'
    end

    context 'if filter_tests_file does not exist' do
      before do
        allow(File).to receive(:exist?).with(filter_tests_file).and_return(false)
      end

      it_behaves_like 'runs node tests'
    end

    context 'without rspec args' do
      let(:rspec_args) { nil }

      it 'runs rspec with without extra arguments' do
        expect_command(%w[bundle exec rspec --default-path spec -- 01_spec.rb 03_spec.rb])

        subject.run
      end
    end

    def expect_command(cmd)
      expect(subject).to receive(:exec).with(*cmd)
    end
  end
end
