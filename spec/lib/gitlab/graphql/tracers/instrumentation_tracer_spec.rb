# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Tracers::InstrumentationTracer, :aggregate_failures, feature_category: :api do
  include GraphqlHelpers

  let(:analyzer_class) do
    Class.new(GraphQL::Analysis::Analyzer) do
      def result
        nil
      end
    end
  end

  let(:query_type) do
    Class.new(Graphql::FakeQueryType) do
      graphql_name 'FakeQuery'

      field :unauthorized_subscription, String, null: true

      def unauthorized_subscription
        raise GraphQL::ExecutionError, Subscriptions::BaseSubscription::UNAUTHORIZED_ERROR_MESSAGE
      end
    end
  end

  let(:schema) do
    tracer = described_class
    analyzer = analyzer_class
    root = query_type

    Class.new(empty_schema) do
      trace_with tracer
      query_analyzer analyzer
      query root
    end
  end

  let(:error_rate) { Gitlab::Metrics::RailsSlis.graphql_query_error_rate }
  let(:apdex) { Gitlab::Metrics::RailsSlis.graphql_query_apdex }

  before do
    allow(Gitlab::GraphqlLogger).to receive(:info)
    allow(error_rate).to receive(:increment)
    allow(apdex).to receive(:increment)
  end

  context 'when an exception is raised during query analysis' do
    before do
      # Only the first analyzer instance raises, so a re-execution (the bug) completes
      # and shows up as a second log line instead of a stack overflow.
      allow_next_instance_of(analyzer_class) do |analyzer|
        allow(analyzer).to receive(:result).and_raise('analysis failed')
      end
    end

    # The query never executed, so `query.result` would re-run the multiplex and
    # re-enter the tracer. https://gitlab.com/gitlab-org/gitlab/-/issues/630513
    it 'does not read the result of the unexecuted query' do
      allow_next_instance_of(GraphQL::Query) do |query|
        expect(query).not_to receive(:result)
      end

      expect { schema.execute('{ helloWorld }') }.to raise_error(RuntimeError, 'analysis failed')
      expect(Gitlab::GraphqlLogger).to have_received(:info).once
    end

    it 'records the query as an error and skips apdex' do
      expect { schema.execute('{ helloWorld }') }.to raise_error(RuntimeError, 'analysis failed')

      expect(error_rate).to have_received(:increment).once.with(a_hash_including(error: true))
      expect(apdex).not_to have_received(:increment)
    end
  end

  context 'when a non-StandardError is raised during query analysis' do
    before do
      allow_next_instance_of(analyzer_class) do |analyzer|
        allow(analyzer).to receive(:result).and_raise(NotImplementedError, 'analysis aborted')
      end
    end

    # The tracer rescues StandardError only, so this reaches `ensure` with no exception
    # and an unexecuted query.
    it 'records an error without reading the result or logging an exception' do
      allow_next_instance_of(GraphQL::Query) do |query|
        expect(query).not_to receive(:result)
      end

      expect { schema.execute('{ helloWorld }') }.to raise_error(NotImplementedError, 'analysis aborted')

      expect(Gitlab::GraphqlLogger).to have_received(:info).once
        .with(hash_excluding('exception.class', :graphql_errors))
      expect(error_rate).to have_received(:increment).once.with(a_hash_including(error: true))
      expect(apdex).not_to have_received(:increment)
    end
  end

  context 'when a StandardError is raised during execution' do
    # graphql-ruby assigns an empty result before re-raising, so the query counts as executed.
    it 'logs the exception once and records an error' do
      expect { schema.execute('{ breakingField }') }.to raise_error(RuntimeError, 'This field is supposed to break')

      expect(Gitlab::GraphqlLogger).to have_received(:info).once.with(a_hash_including(
        'exception.class' => 'RuntimeError', 'exception.message' => 'This field is supposed to break'
      ))
      expect(Gitlab::GraphqlLogger).to have_received(:info).with(hash_excluding(:graphql_errors))
      expect(error_rate).to have_received(:increment).once.with(a_hash_including(error: true))
      expect(apdex).not_to have_received(:increment)
    end
  end

  # Queries rejected before execution are client errors: they are logged but do not
  # count against the error SLI. https://gitlab.com/gitlab-org/gitlab/-/work_items/631498
  shared_examples 'a client error' do |message_pattern|
    it 'logs the errors, records no error, and skips apdex' do
      expect(result['errors']).to contain_exactly(a_hash_including('message' => a_string_matching(message_pattern)))
      expect(Gitlab::GraphqlLogger).to have_received(:info).once.with(a_hash_including(
        graphql_errors: [a_hash_including('message' => a_string_matching(message_pattern))]
      ))
      expect(error_rate).to have_received(:increment).once.with(a_hash_including(error: false))
      expect(apdex).not_to have_received(:increment)
    end
  end

  context 'when the query cannot be parsed' do
    let(:result) { schema.execute('{ helloWorld') }

    it_behaves_like 'a client error', /not end of file/
  end

  context 'when the query fails static validation' do
    let(:result) { schema.execute('{ noSuchField }') }

    it_behaves_like 'a client error', /noSuchField/
  end

  context 'when a required variable is missing' do
    let(:result) { schema.execute('query($message: String!) { helloWorld(message: $message) }', variables: {}) }

    it_behaves_like 'a client error', /\AVariable \$message of type String! was provided invalid value\z/
  end

  context 'when the query exceeds the max complexity' do
    let(:result) { schema.execute('{ helloWorld }', max_complexity: 0) }

    it_behaves_like 'a client error', /exceeds max complexity/
  end

  context 'when validation times out' do
    before do
      allow_next_instance_of(analyzer_class) do |analyzer|
        allow(analyzer).to receive(:result).and_return(GraphQL::Analysis::TimeoutError.new)
      end
    end

    it 'logs the error and records an error' do
      result = schema.execute('{ helloWorld }')

      expect(result['errors'].pluck('message')).to eq([described_class::VALIDATION_TIMEOUT_MESSAGE])
      expect(Gitlab::GraphqlLogger).to have_received(:info).once.with(a_hash_including(
        graphql_errors: [a_hash_including('message' => described_class::VALIDATION_TIMEOUT_MESSAGE)]
      ))
      expect(error_rate).to have_received(:increment).once.with(a_hash_including(error: true))
      expect(apdex).not_to have_received(:increment)
    end
  end

  context 'when a resolver returns an execution error' do
    let(:query_type) do
      Class.new(Graphql::FakeQueryType) do
        graphql_name 'FakeQuery'

        field :failing_field, String, null: true

        def failing_field
          raise GraphQL::ExecutionError, 'Something went wrong'
        end
      end
    end

    it 'records an error' do
      result = schema.execute('{ failingField }')

      expect(result['errors'].pluck('message')).to eq(['Something went wrong'])
      expect(error_rate).to have_received(:increment).once.with(a_hash_including(error: true))
      expect(apdex).not_to have_received(:increment)
    end
  end

  context 'when every error is in IGNORED_ERRORS' do
    it 'logs the errors, records no error, and skips apdex' do
      result = schema.execute('{ unauthorizedSubscription }')

      expect(result['errors'].pluck('message')).to eq([Subscriptions::BaseSubscription::UNAUTHORIZED_ERROR_MESSAGE])
      expect(Gitlab::GraphqlLogger).to have_received(:info).once.with(a_hash_including(
        graphql_errors: [a_hash_including('message' => Subscriptions::BaseSubscription::UNAUTHORIZED_ERROR_MESSAGE)]
      ))
      expect(error_rate).to have_received(:increment).once.with(a_hash_including(error: false))
      expect(apdex).not_to have_received(:increment)
    end
  end

  context 'when the query executes' do
    it 'logs the query once with its result' do
      expect(schema.execute('{ helloWorld }')['data']).to eq('helloWorld' => 'Hello world!')

      expect(Gitlab::GraphqlLogger).to have_received(:info).once.with(hash_excluding(:graphql_errors))
      expect(error_rate).to have_received(:increment).once.with(a_hash_including(error: false))
      expect(apdex).to have_received(:increment).once
    end
  end
end
