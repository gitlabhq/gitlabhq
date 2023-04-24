# frozen_string_literal: true

require 'tempfile'

require_relative '../../../../tooling/lib/tooling/parallel_rspec_runner'

RSpec.describe Tooling::ParallelRSpecRunner do # rubocop:disable RSpec/FilePath
  describe '#run' do
    let(:test_dir) { 'spec' }
    let(:node_tests) { %w[01_spec.rb 03_spec.rb] }
    let(:allocator) { instance_double(Knapsack::Allocator, test_dir: test_dir, node_tests: node_tests) }
    let(:allocator_builder) { double(Knapsack::AllocatorBuilder, allocator: allocator) } # rubocop:disable RSpec/VerifiedDoubles

    let(:filter_tests) { [] }
    let(:filter_tests_file) { nil }
    let(:filter_tests_file_path) { nil }

    before do
      allow(Knapsack::AllocatorBuilder).to receive(:new).and_return(allocator_builder)
      allow(Knapsack.logger).to receive(:info)
    end

    after do
      if filter_tests_file.respond_to?(:close)
        filter_tests_file.close
        File.unlink(filter_tests_file)
      end
    end

    subject { described_class.new(filter_tests_file: filter_tests_file_path, rspec_args: rspec_args) }

    shared_examples 'runs node tests' do
      let(:rspec_args) { nil }

      it 'runs rspec with tests allocated for this node' do
        expect(allocator_builder).to receive(:filter_tests=).with(filter_tests)
        expect_command(%W[bundle exec rspec#{rspec_args} --] + node_tests)

        subject.run
      end
    end

    context 'without filter_tests_file option' do
      subject { described_class.new(rspec_args: rspec_args) }

      it_behaves_like 'runs node tests'
    end

    context 'given filter tests file' do
      let(:filter_tests_file) do
        Tempfile.create.tap do |f| # rubocop:disable Rails/SaveBang
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

    def expect_command(cmd)
      expect(subject).to receive(:exec).with(*cmd)
    end
  end
end
