# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Json::SafeParser, :aggregate_failures, feature_category: :shared do # rubocop:disable RSpec/FeatureCategory -- These are tests for a shared library
  let(:parser) { described_class.new(**options) }
  let(:options) { {} }

  describe 'initializer' do
    context 'when an unknown configuration option is provided' do
      let(:options) { { foo: 1 } }

      it 'raises `UnknownConfigurationError`' do
        expect { parser }.to raise_error(described_class::UnknownConfigurationError)
      end
    end

    context 'when no unknown configuration option provided' do
      let(:options) { { max_depth: 1 } }

      it 'does not raise any error' do
        expect(parser).to be_an_instance_of(described_class)
      end
    end
  end

  shared_examples_for 'parsing a JSON document' do
    let(:default_parse_limits) do
      {
        max_depth: 2,
        max_array_size: 2,
        max_hash_size: 2,
        max_total_elements: 7,
        max_json_size_bytes: 40.bytes
      }
    end

    before do
      stub_const('Gitlab::Json::PARSE_LIMITS', default_parse_limits)
    end

    shared_examples_for 'raising a validation error' do |json, expected_error|
      subject(:parse) { parser_method.call(json) }

      it 'raises a validation error' do
        expect { parse }.to raise_error(JSON::ParserError, expected_error)
      end
    end

    shared_examples_for 'parsing without error' do |json, expected|
      subject(:parse) { parser_method.call(json) }

      it 'parses without error' do
        expect(parse).to eq(expected)
      end
    end

    context 'when no options provided' do
      context 'when given JSON is deeper than the default max depth' do
        it_behaves_like 'raising a validation error', '[[[]]]', 'Parameters nested too deeply'
      end

      context 'when given JSON has a bigger array than allowed' do
        it_behaves_like 'raising a validation error', '[1, 2, 3]', 'Array parameter too large'
      end

      context 'when given JSON has a bigger object than allowed' do
        it_behaves_like 'raising a validation error', '{ "foo": 1, "bar": 2, "baz": 3 }', 'Hash parameter too large'
      end

      context 'when given JSON has a more elements than allowed' do
        it_behaves_like 'raising a validation error',
          '[{ "foo": 1 }, { "foo": 1, "bar": 2 }]',
          'Too many total parameters'
      end

      context 'when given JSON is bigger than allowed' do
        it_behaves_like 'raising a validation error', "\"#{'a' * 39}\"", 'JSON body too large'
      end

      context 'when given JSON is valid' do
        it_behaves_like 'parsing without error', '[{ "foo": 1, "bar": 2}]', [{ 'foo' => 1, 'bar' => 2 }]
      end
    end

    context 'when options provided' do
      context 'with `max_depth` option' do
        context 'when the provided option is nil' do
          let(:options) { { max_depth: nil } }

          it_behaves_like 'parsing without error', '[[[{}]]]', [[[{}]]]
        end

        context 'when the provided option is not nil' do
          let(:options) { { max_depth: 3 } }

          context 'when given JSON is deeper than the `max_depth` option' do
            it_behaves_like 'raising a validation error', '[[[{}]]]', 'Parameters nested too deeply'
          end

          context 'when given JSON is not deeper than the `max_depth` option' do
            it_behaves_like 'parsing without error', '[[{}]]', [[{}]]
          end
        end
      end

      context 'with `max_array_size` option' do
        context 'when the provided option is nil' do
          let(:options) { { max_array_size: nil } }

          it_behaves_like 'parsing without error', '[1, 2, 3, 4]', [1, 2, 3, 4]
        end

        context 'when the provided option is not nil' do
          let(:options) { { max_array_size: 3 } }

          context 'when given JSON has an array with more items than `max_array_size` option' do
            it_behaves_like 'raising a validation error', '[1, 2, 3, 4]', 'Array parameter too large'
          end

          context 'when given JSON does not have any array with more items than `max_array_size` option' do
            it_behaves_like 'parsing without error', '[1, 2, 3]', [1, 2, 3]
          end
        end
      end

      context 'with `max_hash_size` option' do
        context 'when the provided option is nil' do
          let(:options) { { max_hash_size: nil } }

          it_behaves_like 'parsing without error',
            '{ "foo": 1, "bar": 2, "baz": 3 }',
            { 'foo' => 1, 'bar' => 2, 'baz' => 3 }
        end

        context 'when the provided option is not nil' do
          let(:options) { { max_hash_size: 1 } }

          context 'when given JSON has an object with more items than `max_hash_size` option' do
            it_behaves_like 'raising a validation error', '{ "foo": 1, "bar": 2 }', 'Hash parameter too large'
          end

          context 'when given JSON does not have any object with more items than `max_hash_size` option' do
            it_behaves_like 'parsing without error', '{ "foo": 1 }', { 'foo' => 1 }
          end
        end
      end

      context 'with `max_total_elements` option' do
        context 'when the provided option is nil' do
          let(:options) { { max_total_elements: nil } }

          it_behaves_like 'parsing without error',
            '[{ "foo": 1 }, { "foo": 1, "bar": 2 }]',
            [{ 'foo' => 1 }, { 'foo' => 1, 'bar' => 2 }]
        end

        context 'when the provided option is not nil' do
          let(:options) { { max_total_elements: 1 } }

          context 'when given JSON has more elements than `max_total_elements` option' do
            it_behaves_like 'raising a validation error', '["foo"]', 'Too many total parameters'
          end

          context 'when given JSON does not have more elements than `max_total_elements` option' do
            it_behaves_like 'parsing without error', '"foo"', 'foo'
          end
        end
      end

      context 'with `max_json_size_bytes` option' do
        context 'when the provided option is nil' do
          let(:options) { { max_json_size_bytes: nil } }

          it_behaves_like 'parsing without error', "\"#{'a' * 39}\"", ('a' * 39)
        end

        context 'when the provided option is not nil' do
          let(:options) { { max_json_size_bytes: 5 } }

          context 'when given JSON is bigger than `max_json_size_bytes` option' do
            it_behaves_like 'raising a validation error', '123456', 'JSON body too large'
          end

          context 'when given JSON is not bigger than `max_json_size_bytes` option' do
            it_behaves_like 'parsing without error', '12345', 12345
          end
        end
      end
    end

    context 'when the given JSON payload is malformed' do
      it_behaves_like 'raising a validation error', '[}', 'unexpected object close at 1:3'
    end
  end

  describe '#parse' do
    it_behaves_like 'parsing a JSON document' do
      let(:parser_method) { ->(json) { parser.parse(json) } }
    end

    describe 'parser thread affinity' do
      around do |example|
        old_report_on_exception = Thread.report_on_exception
        old_abort_on_exception = Thread.abort_on_exception

        Thread.report_on_exception = false
        Thread.abort_on_exception = true

        example.run
      ensure
        Thread.report_on_exception = old_report_on_exception
        Thread.abort_on_exception = old_abort_on_exception
      end

      it 'raises a ConcurrencyError when used by a different thread' do
        parser # create parser in the main thread

        expect { Thread.new { parser.parse('') }.value }.to raise_error(described_class::ConcurrencyError)
      end
    end
  end

  describe '.parse' do
    it_behaves_like 'parsing a JSON document' do
      let(:parser_method) { ->(json) { described_class.parse(json, **options) } }
    end

    describe 'different options handling' do
      let(:options_1) { { max_array_size: 1 } }
      let(:options_2) { { max_array_size: 2 } }
      let(:payload) { '[1, 2]' }

      it 'uses correct options' do
        expect { described_class.parse(payload, **options_1) }.to raise_error(Gitlab::Json.parser_error)
        expect { described_class.parse(payload, **options_2) }.not_to raise_error
      end
    end

    describe 'thread safety' do
      let(:options) { { max_array_size: 1 } }

      before do
        Thread.current[described_class::THREAD_CACHE_NAMESPACE] = nil
      end

      it 'uses a different parser instance per thread' do
        mock_parser_instance(:from_first_instance)

        expect(described_class.parse('')).to eq(:from_first_instance)

        mock_parser_instance(:from_second_instance)

        expect(described_class.parse('')).to eq(:from_first_instance) # using the same instance within the same thread

        sub_thread_value = Thread.new { described_class.parse('') }.value
        expect(sub_thread_value).to eq(:from_second_instance)
      end

      def mock_parser_instance(return_value)
        allow_next_instance_of(described_class, **Gitlab::Json::PARSE_LIMITS) do |parser_instance|
          allow(parser_instance).to receive(:parse).and_return(return_value)
        end
      end
    end
  end
end
