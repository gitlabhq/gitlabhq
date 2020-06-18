# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::ErrorTracking::Processor::SidekiqProcessor do
  after do
    if described_class.instance_variable_defined?(:@permitted_arguments_for_worker)
      described_class.remove_instance_variable(:@permitted_arguments_for_worker)
    end
  end

  describe '.filter_arguments' do
    it 'returns a lazy enumerator' do
      filtered = described_class.filter_arguments([1, 'string'], 'TestWorker')

      expect(filtered).to be_a(Enumerator::Lazy)
      expect(filtered.to_a).to eq([1, described_class::FILTERED_STRING])
    end

    context 'arguments filtering' do
      using RSpec::Parameterized::TableSyntax

      where(:klass, :expected) do
        'UnknownWorker' | [1, described_class::FILTERED_STRING, described_class::FILTERED_STRING, described_class::FILTERED_STRING]
        'NoPermittedArguments' | [1, described_class::FILTERED_STRING, described_class::FILTERED_STRING, described_class::FILTERED_STRING]
        'OnePermittedArgument' | [1, 'string', described_class::FILTERED_STRING, described_class::FILTERED_STRING]
        'AllPermittedArguments' | [1, 'string', [1, 2], { a: 1 }]
      end

      with_them do
        before do
          stub_const('NoPermittedArguments', double(loggable_arguments: []))
          stub_const('OnePermittedArgument', double(loggable_arguments: [1]))
          stub_const('AllPermittedArguments', double(loggable_arguments: [0, 1, 2, 3]))
        end

        it do
          expect(described_class.filter_arguments([1, 'string', [1, 2], { a: 1 }], klass).to_a)
            .to eq(expected)
        end
      end
    end
  end

  describe '.permitted_arguments_for_worker' do
    it 'returns the loggable_arguments for a worker class as a set' do
      stub_const('TestWorker', double(loggable_arguments: [1, 1]))

      expect(described_class.permitted_arguments_for_worker('TestWorker'))
        .to eq([1].to_set)
    end

    it 'returns an empty set when the worker class does not exist' do
      expect(described_class.permitted_arguments_for_worker('TestWorker'))
        .to eq(Set.new)
    end

    it 'returns an empty set when the worker class does not respond to loggable_arguments' do
      stub_const('TestWorker', 1)

      expect(described_class.permitted_arguments_for_worker('TestWorker'))
        .to eq(Set.new)
    end

    it 'returns an empty set when loggable_arguments cannot be converted to a set' do
      stub_const('TestWorker', double(loggable_arguments: 1))

      expect(described_class.permitted_arguments_for_worker('TestWorker'))
        .to eq(Set.new)
    end

    it 'memoizes the results' do
      worker_class = double

      stub_const('TestWorker', worker_class)

      expect(worker_class).to receive(:loggable_arguments).once.and_return([])

      described_class.permitted_arguments_for_worker('TestWorker')
      described_class.permitted_arguments_for_worker('TestWorker')
    end
  end

  describe '.loggable_arguments' do
    it 'filters and limits the arguments, then converts to strings' do
      half_limit = Gitlab::Utils::LogLimitedArray::MAXIMUM_ARRAY_LENGTH / 2
      args = [[1, 2], 'a' * half_limit, 'b' * half_limit, 'c' * half_limit, 'd']

      stub_const('LoggableArguments', double(loggable_arguments: [0, 1, 3, 4]))

      expect(described_class.loggable_arguments(args, 'LoggableArguments'))
        .to eq(['[1, 2]', 'a' * half_limit, '[FILTERED]', '...'])
    end
  end

  describe '#process' do
    context 'when there is Sidekiq data' do
      shared_examples 'Sidekiq arguments' do |args_in_job_hash: true|
        let(:path) { [:extra, :sidekiq, args_in_job_hash ? :job : nil, 'args'].compact }
        let(:args) { [1, 'string', { a: 1 }, [1, 2]] }

        it 'only allows numeric arguments for an unknown worker' do
          value = { 'args' => args, 'class' => 'UnknownWorker' }

          value = { job: value } if args_in_job_hash

          expect(subject.process(extra_sidekiq(value)).dig(*path))
            .to eq([1, described_class::FILTERED_STRING, described_class::FILTERED_STRING, described_class::FILTERED_STRING])
        end

        it 'allows all argument types for a permitted worker' do
          value = { 'args' => args, 'class' => 'PostReceive' }

          value = { job: value } if args_in_job_hash

          expect(subject.process(extra_sidekiq(value)).dig(*path))
            .to eq(args)
        end
      end

      context 'when processing via the default error handler' do
        include_examples 'Sidekiq arguments', args_in_job_hash: true
      end

      context 'when processing via Gitlab::ErrorTracking' do
        include_examples 'Sidekiq arguments', args_in_job_hash: false
      end

      it 'removes a jobstr field if present' do
        value = {
          job: { 'args' => [1] },
          jobstr: { 'args' => [1] }.to_json
        }

        expect(subject.process(extra_sidekiq(value)))
          .to eq(extra_sidekiq(value.except(:jobstr)))
      end

      it 'does nothing with no jobstr' do
        value = { job: { 'args' => [1] } }

        expect(subject.process(extra_sidekiq(value)))
          .to eq(extra_sidekiq(value))
      end
    end

    context 'when there is no Sidekiq data' do
      it 'does nothing' do
        value = {
          request: {
            method: 'POST',
            data: { 'key' => 'value' }
          }
        }

        expect(subject.process(value)).to eq(value)
      end
    end

    def extra_sidekiq(hash)
      { extra: { sidekiq: hash } }
    end
  end
end
