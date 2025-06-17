# frozen_string_literal: true

require 'fast_spec_helper'

# NOTE:
#       This spec is intended to serve as documentation examples of idiomatic usage for the `Result` type.
#       These examples can be executed as-is in a Rails console to see the results.
#
#       To support this, we have intentionally used some `rubocop:disable` and RubyMine `noinspection` comments
#       to allow for more explicit and readable examples.
#
#       There is also not much attempt to DRY up the examples. There is some duplication, but this is intentional to
#       support easily understandable and readable examples.
#
# rubocop:disable RSpec/DescribedClass, Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration -- intentionally disabled per comment above
# noinspection MissingYardReturnTag, MissingYardParamTag - intentionally disabled per comment above
RSpec.describe Gitlab::Fp::Result, feature_category: :shared do
  describe 'usage of Gitlab::Fp::Result.ok and Gitlab::Fp::Result.err' do
    context 'when checked with .ok? and .err?' do
      it 'works with ok result' do
        result = Gitlab::Fp::Result.ok(:success)
        expect(result.ok?).to be(true)
        expect(result.err?).to be(false)
        expect(result.unwrap).to eq(:success)
      end

      it 'works with error result' do
        result = Gitlab::Fp::Result.err(:failure)
        expect(result.err?).to be(true)
        expect(result.ok?).to be(false)
        expect(result.unwrap_err).to eq(:failure)
      end
    end

    context 'when checked with destructuring' do
      it 'works with ok result' do
        Gitlab::Fp::Result.ok(:success) => { ok: } # example of rightward assignment
        expect(ok).to eq(:success)

        Gitlab::Fp::Result.ok(:success) => { ok: success_value } # rightward assignment destructuring to different var
        expect(success_value).to eq(:success)
      end

      it 'works with error result' do
        Gitlab::Fp::Result.err(:failure) => { err: }
        expect(err).to eq(:failure)

        Gitlab::Fp::Result.err(:failure) => { err: error_value }
        expect(error_value).to eq(:failure)
      end
    end

    context 'when checked with pattern matching' do
      def check_result_with_pattern_matching(result)
        case result
        in { ok: Symbol => ok_value }
          { success: ok_value }
        in { err: String => error_value }
          { failure: error_value }
        else
          raise "Unmatched result type: #{result.unwrap.class.name}"
        end
      end

      it 'works with ok result' do
        ok_result = Gitlab::Fp::Result.ok(:success_symbol)
        expect(check_result_with_pattern_matching(ok_result)).to eq({ success: :success_symbol })
      end

      it 'works with error result' do
        error_result = Gitlab::Fp::Result.err('failure string')
        expect(check_result_with_pattern_matching(error_result)).to eq({ failure: 'failure string' })
      end

      it 'raises error with unmatched type in pattern match' do
        unmatched_type_result = Gitlab::Fp::Result.ok([])
        expect do
          check_result_with_pattern_matching(unmatched_type_result)
        end.to raise_error(RuntimeError, 'Unmatched result type: Array')
      end

      it 'raises error with invalid pattern matching key' do
        result = Gitlab::Fp::Result.ok(:success)
        expect do
          case result
          in { invalid_pattern_match_because_it_is_not_ok_or_err: :value }
            :unreachable_from_case
          else
            :unreachable_from_else
          end
        end.to raise_error(ArgumentError, 'Use either :ok or :err for pattern matching')
      end
    end
  end

  describe 'usage of #and_then' do
    context 'when passed a proc' do
      it 'returns last ok value in successful chain' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .and_then(->(value) { Gitlab::Fp::Result.ok(value + 1) })
            .and_then(->(value) { Gitlab::Fp::Result.ok(value + 1) })

        expect(final_result.ok?).to be(true)
        expect(final_result.unwrap).to eq(3)
      end

      it 'short-circuits the rest of the chain on the first err value encountered' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .and_then(->(value) { Gitlab::Fp::Result.err("invalid: #{value}") })
            .and_then(->(value) { Gitlab::Fp::Result.ok(value + 1) })

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to eq('invalid: 1')
      end
    end

    context 'when passed a module or class (singleton) method object' do
      module MyModuleUsingResult
        def self.double(value)
          Gitlab::Fp::Result.ok(value * 2)
        end

        def self.return_err(value)
          Gitlab::Fp::Result.err("invalid: #{value}")
        end

        class MyClassUsingResult
          def self.triple(value)
            Gitlab::Fp::Result.ok(value * 3)
          end
        end
      end

      it 'returns last ok value in successful chain' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .and_then(::MyModuleUsingResult.method(:double))
            .and_then(::MyModuleUsingResult::MyClassUsingResult.method(:triple))

        expect(final_result.ok?).to be(true)
        expect(final_result.unwrap).to eq(6)
      end

      it 'returns first err value in failed chain' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .and_then(::MyModuleUsingResult.method(:double))
            .and_then(::MyModuleUsingResult::MyClassUsingResult.method(:triple))
            .and_then(::MyModuleUsingResult.method(:return_err))
            .and_then(::MyModuleUsingResult.method(:double))

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to eq('invalid: 6')
      end
    end

    describe 'type checking validation' do
      describe 'enforcement of argument type' do
        it 'raises TypeError if passed anything other than a lambda or singleton method object' do
          ex = TypeError
          msg = /Result#and_then expects a lambda or singleton method object/
          # noinspection RubyMismatchedArgumentType -- intentionally passing invalid types
          expect { Gitlab::Fp::Result.ok(1).and_then('string') }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).and_then(proc { Gitlab::Fp::Result.ok(1) }) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).and_then(1.method(:to_s)) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).and_then(Integer.method(:to_s)) }.to raise_error(ex, msg)
        end
      end

      describe 'enforcement of argument arity' do
        it 'raises ArgumentError if passed lambda or singleton method object with an arity other than 1' do
          expect do
            Gitlab::Fp::Result.ok(1).and_then(->(a, b) { Gitlab::Fp::Result.ok(a + b) })
          end.to raise_error(ArgumentError, /Result#and_then expects .* with a single argument \(arity of 1\)/)
        end
      end

      describe 'enforcement that passed lambda or method returns a Gitlab::Fp::Result type' do
        it 'raises ArgumentError if passed lambda or singleton method object which returns non-Result type' do
          expect do
            Gitlab::Fp::Result.ok(1).and_then(->(a) { a + 1 })
          end.to raise_error(TypeError, /Result#and_then expects .* which returns a 'Result' type/)
        end
      end
    end
  end

  describe 'usage of #map' do
    context 'when passed a proc' do
      it 'returns last ok value in successful chain' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .map(->(value) { value + 1 })
            .map(->(value) { value + 1 })

        expect(final_result.ok?).to be(true)
        expect(final_result.unwrap).to eq(3)
      end

      it 'returns first err value in failed chain' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .and_then(->(value) { Gitlab::Fp::Result.err("invalid: #{value}") })
            .map(->(value) { value + 1 })

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to eq('invalid: 1')
      end
    end

    context 'when passed a module or class (singleton) method object' do
      module MyModuleNotUsingResult
        def self.double(value)
          value * 2
        end

        class MyClassNotUsingResult
          def self.triple(value)
            value * 3
          end
        end
      end

      it 'returns last ok value in successful chain' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .map(::MyModuleNotUsingResult.method(:double))
            .map(::MyModuleNotUsingResult::MyClassNotUsingResult.method(:triple))

        expect(final_result.ok?).to be(true)
        expect(final_result.unwrap).to eq(6)
      end

      it 'returns first err value in failed chain' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .map(::MyModuleNotUsingResult.method(:double))
            .and_then(->(value) { Gitlab::Fp::Result.err("invalid: #{value}") })
            .map(::MyModuleUsingResult.method(:double))

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to eq('invalid: 2')
      end
    end

    describe 'type checking validation' do
      describe 'enforcement of argument type' do
        it 'raises TypeError if passed anything other than a lambda or singleton method object' do
          ex = TypeError
          msg = /Result#map expects a lambda or singleton method object/
          # noinspection RubyMismatchedArgumentType -- intentionally passing invalid types
          expect { Gitlab::Fp::Result.ok(1).map('string') }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).map(proc { 1 }) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).map(1.method(:to_s)) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).map(Integer.method(:to_s)) }.to raise_error(ex, msg)
        end
      end

      describe 'enforcement of argument arity' do
        it 'raises ArgumentError if passed lambda or singleton method object with an arity other than 1' do
          expect do
            Gitlab::Fp::Result.ok(1).map(->(a, b) { a + b })
          end.to raise_error(ArgumentError, /Result#map expects .* with a single argument \(arity of 1\)/)
        end
      end

      describe 'enforcement that passed lambda or method does not return a Result type' do
        it 'raises TypeError if passed lambda or singleton method object which returns non-Result type' do
          expect do
            Gitlab::Fp::Result.ok(1).map(->(a) { Gitlab::Fp::Result.ok(a + 1) })
          end.to raise_error(TypeError, /Result#map expects .* which returns an unwrapped value, not a 'Result'/)
        end
      end
    end
  end

  describe 'usage of #map_err' do
    context 'when passed a proc' do
      it 'ignores ok values in successful chain' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .map_err(->(value) { value + 1 })

        expect(final_result.ok?).to be(true)
        expect(final_result.unwrap).to eq(1)
      end

      it 'returns first err value in failed chain' do
        initial_result = Gitlab::Fp::Result.ok(1)
        final_result =
          initial_result
            .and_then(->(value) { Gitlab::Fp::Result.err("invalid: #{value}") })
            .map_err(->(value) { "#{value}, with map_err" })

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to eq('invalid: 1, with map_err')
      end
    end

    context 'when passed a module or class (singleton) method object' do
      module MyModuleNotUsingResult
        def self.double(value)
          value * 2
        end

        class MyClassNotUsingResult
          def self.triple(value)
            value * 3
          end
        end
      end

      it 'processes the err value in failed chain' do
        initial_result = Gitlab::Fp::Result.err(1)
        final_result =
          initial_result
            .map_err(::MyModuleNotUsingResult.method(:double))
            .map_err(::MyModuleNotUsingResult::MyClassNotUsingResult.method(:triple))

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to eq(6)
      end
    end

    describe 'type checking validation' do
      describe 'enforcement of argument type' do
        it 'raises TypeError if passed anything other than a lambda or singleton method object' do
          ex = TypeError
          msg = /Result#map_err expects a lambda or singleton method object/
          # noinspection RubyMismatchedArgumentType -- intentionally passing invalid types
          expect { Gitlab::Fp::Result.ok(1).map_err('string') }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).map_err(proc { 1 }) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).map_err(1.method(:to_s)) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).map_err(Integer.method(:to_s)) }.to raise_error(ex, msg)
        end
      end

      describe 'enforcement of argument arity' do
        it 'raises ArgumentError if passed lambda or singleton method object with an arity other than 1' do
          expect do
            Gitlab::Fp::Result.ok(1).map_err(->(a, b) { a + b })
          end.to raise_error(ArgumentError, /Result#map_err expects .* with a single argument \(arity of 1\)/)
        end
      end

      describe 'enforcement that passed lambda or method does not return a Result type' do
        it 'raises TypeError if passed lambda or singleton method object which returns non-Result type' do
          expect do
            Gitlab::Fp::Result.err(1).map_err(->(a) { Gitlab::Fp::Result.ok(a + 1) })
          end.to raise_error(TypeError, /Result#map_err expects .* which returns an unwrapped value, not a 'Result'/)
        end
      end
    end
  end

  describe 'usage of #inspect_ok' do
    let(:logger) { instance_double(Logger, :info) }

    context 'when passed a proc' do
      it 'returns last ok value in successful chain and performs side effect' do
        expect(logger).to receive(:info)

        initial_result = Gitlab::Fp::Result.ok({ logger: logger })
        final_result =
          initial_result
            .inspect_ok(->(context) { context[:logger].info })

        expect(final_result.ok?).to be(true)
        expect(final_result.unwrap).to eq({ logger: logger })
      end

      it 'returns first err value in failed chain and does not perform side effect' do
        expect(logger).not_to receive(:info)

        initial_result = Gitlab::Fp::Result.ok({ logger: logger })
        final_result =
          initial_result
            .and_then(->(value) { Gitlab::Fp::Result.err("invalid: #{value}") })
            .inspect_ok(->(context) { context[:logger].info })

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to match(/invalid:.*logger.*:info/)
      end

      it 'cannot modify the Result passed along the chain', :unlimited_max_formatted_output_length do
        initial_result = Gitlab::Fp::Result.ok({ logger: logger })
        expect do
          initial_result.inspect_ok(->(context) { context[:logger] = nil })
        end.to raise_error(
          RuntimeError, /Proc:.*must not modify the passed value.*because it was invoked via Result#inspect_ok/
        )
      end
    end

    context 'when passed a module or class (singleton) method object' do
      module MyModuleNotUsingResult
        def self.observe(context)
          context[:logger].info
        end

        def self.modify!(context)
          context[:logger] = "MODIFIED VALUE"
          nil
        end
      end

      it 'returns last ok value in successful chain and performs side effect' do
        expect(logger).to receive(:info)

        initial_result = Gitlab::Fp::Result.ok({ logger: logger })
        final_result =
          initial_result
            .inspect_ok(::MyModuleNotUsingResult.method(:observe))

        expect(final_result.ok?).to be(true)
        expect(final_result.unwrap).to eq({ logger: logger })
      end

      it 'returns first err value in failed chain and does not perform side effect' do
        expect(logger).not_to receive(:info)

        initial_result = Gitlab::Fp::Result.ok({ logger: logger })
        final_result =
          initial_result
            .and_then(->(value) { Gitlab::Fp::Result.err("invalid: #{value}") })
            .inspect_ok(::MyModuleNotUsingResult.method(:observe))

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to match(/invalid:.*logger.*:info/)
      end

      it 'cannot modify the Result passed along the chain', :unlimited_max_formatted_output_length do
        initial_result = Gitlab::Fp::Result.ok({ logger: logger })
        expect do
          initial_result.inspect_ok(::MyModuleNotUsingResult.method(:modify!))
        end.to raise_error(
          RuntimeError,
          /Method: MyModuleNotUsingResult.modify!\(context\).*not modify the.*value.*invoked via Result#inspect_ok/
        )
      end
    end

    describe 'type checking validation' do
      describe 'enforcement of argument type' do
        it 'raises TypeError if passed anything other than a lambda or singleton method object',
          :unlimited_max_formatted_output_length do
          ex = TypeError
          msg = /Result#inspect_ok expects a lambda or singleton method object/
          # noinspection RubyMismatchedArgumentType -- intentionally passing invalid types
          expect { Gitlab::Fp::Result.ok(1).inspect_ok('string') }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).inspect_ok(proc { 1 }) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).inspect_ok(1.method(:to_s)) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).inspect_ok(Integer.method(:to_s)) }.to raise_error(ex, msg)
        end
      end

      describe 'enforcement of argument arity' do
        it 'raises ArgumentError if passed lambda or singleton method object with an arity other than 1' do
          expect do
            Gitlab::Fp::Result.ok(1).inspect_ok(->(a, b) { a + b })
          end.to raise_error(ArgumentError, /Result#inspect_ok expects .* with a single argument \(arity of 1\)/)
        end
      end

      describe 'enforcement that passed lambda or method returns nil (void)' do
        it 'raises TypeError if passed lambda or singleton method object which does not return nil' do
          expect do
            Gitlab::Fp::Result.ok(1).inspect_ok(->(_) { "not nil" })
          end.to raise_error(TypeError, /Result#inspect_ok.*must always return 'nil'/)
        end
      end
    end
  end

  describe 'usage of #inspect_err' do
    let(:logger) { instance_double(Logger, :info) }

    context 'when passed a proc' do
      it 'returns last ok value in successful chain and does not performs side effect' do
        expect(logger).not_to receive(:info)

        initial_result = Gitlab::Fp::Result.ok({ logger: logger })
        final_result =
          initial_result
            .inspect_err(->(context) { context[:logger].info })

        expect(final_result.ok?).to be(true)
        expect(final_result.unwrap).to eq({ logger: logger })
      end

      it 'returns first err value in failed chain and performs side effect' do
        expect(logger).to receive(:info)

        initial_result = Gitlab::Fp::Result.err({ logger: logger })
        final_result =
          initial_result
            .inspect_err(->(context) { context[:logger].info })

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to eq({ logger: logger })
      end

      it 'cannot modify the Result passed along the chain', :unlimited_max_formatted_output_length do
        initial_result = Gitlab::Fp::Result.err({ logger: logger })
        expect do
          initial_result.inspect_err(->(context) { context[:logger] = nil })
        end.to raise_error(
          RuntimeError, /Proc:.*must not modify the passed value.*because it was invoked via Result.inspect_err/
        )
      end
    end

    context 'when passed a module or class (singleton) method object' do
      module MyModuleNotUsingResult
        def self.observe(context)
          context[:logger].info
        end
      end

      it 'returns last ok value in successful chain and does not perform side effect' do
        expect(logger).not_to receive(:info)

        initial_result = Gitlab::Fp::Result.ok({ logger: logger })
        final_result =
          initial_result
            .inspect_err(::MyModuleNotUsingResult.method(:observe))

        expect(final_result.ok?).to be(true)
        expect(final_result.unwrap).to eq({ logger: logger })
      end

      it 'returns first err value in failed chain and performs side effect' do
        expect(logger).to receive(:info)

        initial_result = Gitlab::Fp::Result.ok({ logger: logger })
        final_result =
          initial_result
            .and_then(->(value) { Gitlab::Fp::Result.err(value) })
            .inspect_err(::MyModuleNotUsingResult.method(:observe))

        expect(final_result.err?).to be(true)
        expect(final_result.unwrap_err).to eq({ logger: logger })
      end

      it 'cannot modify the Result passed along the chain', :unlimited_max_formatted_output_length do
        initial_result = Gitlab::Fp::Result.err({ logger: logger })
        expect do
          initial_result.inspect_err(::MyModuleNotUsingResult.method(:modify!))
        end.to raise_error(
          RuntimeError,
          /Method: MyModuleNotUsingResult.modify!\(context\).*not modify the.*value.*invoked via Result#inspect_err/
        )
      end
    end

    describe 'type checking validation' do
      describe 'enforcement of argument type' do
        it 'raises TypeError if passed anything other than a lambda or singleton method object' do
          ex = TypeError
          msg = /Result#inspect_err expects a lambda or singleton method object/
          # noinspection RubyMismatchedArgumentType -- intentionally passing invalid types
          expect { Gitlab::Fp::Result.ok(1).inspect_err('str') }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).inspect_err(proc { 1 }) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).inspect_err(1.method(:to_s)) }.to raise_error(ex, msg)
          expect { Gitlab::Fp::Result.ok(1).inspect_err(Integer.method(:to_s)) }.to raise_error(ex, msg)
        end
      end

      describe 'enforcement of argument arity' do
        it 'raises ArgumentError if passed lambda or singleton method object with an arity other than 1' do
          expect do
            Gitlab::Fp::Result.err(1).inspect_err(->(a, b) { a + b })
          end.to raise_error(ArgumentError, /Result#inspect_err expects .* with a single argument \(arity of 1\)/)
        end
      end

      describe 'enforcement that passed lambda or method returns nil (void)' do
        it 'raises TypeError if passed lambda or singleton method object which does not return nil' do
          expect do
            Gitlab::Fp::Result.err(1).inspect_err(->(_) { "not nil" })
          end.to raise_error(TypeError, /Result#inspect_err.*must always return 'nil'/)
        end
      end
    end
  end

  describe '#unwrap' do
    it 'returns wrapped value if ok' do
      expect(Gitlab::Fp::Result.ok(1).unwrap).to eq(1)
    end

    it 'raises error if err' do
      expect { Gitlab::Fp::Result.err('error').unwrap }
        .to raise_error(RuntimeError, /called.*unwrap.*on an 'err' Result/i)
    end
  end

  describe '#unwrap_err' do
    it 'returns wrapped value if err' do
      expect(Gitlab::Fp::Result.err('error').unwrap_err).to eq('error')
    end

    it 'raises error if ok' do
      expect { Gitlab::Fp::Result.ok(1).unwrap_err }
        .to raise_error(RuntimeError, /called.*unwrap_err.*on an 'ok' Result/i)
    end
  end

  describe '#==' do
    it 'implements equality' do
      # rubocop:disable RSpec/IdenticalEqualityAssertion -- We are testing equality
      expect(Gitlab::Fp::Result.ok(1)).to eq(Gitlab::Fp::Result.ok(1))
      expect(Gitlab::Fp::Result.err('error')).to eq(Gitlab::Fp::Result.err('error'))
      expect(Gitlab::Fp::Result.ok(1)).not_to eq(Gitlab::Fp::Result.ok(2))
      expect(Gitlab::Fp::Result.err('error')).not_to eq(Gitlab::Fp::Result.err('other error'))
      expect(Gitlab::Fp::Result.ok(1)).not_to eq(Gitlab::Fp::Result.err(1))
      # rubocop:enable RSpec/IdenticalEqualityAssertion
    end
  end

  describe 'validation' do
    context 'for enforcing usage of only public interface' do
      context 'when private constructor is called with invalid params' do
        it 'raises ArgumentError if both ok_value and err_value are passed' do
          expect { Gitlab::Fp::Result.new(ok_value: :ignored, err_value: :ignored) }
            .to raise_error(ArgumentError, 'Do not directly use private constructor, use Result.ok or Result.err')
        end

        it 'raises ArgumentError if neither ok_value nor err_value are passed' do
          expect { Gitlab::Fp::Result.new }
            .to raise_error(ArgumentError, 'Do not directly use private constructor, use Result.ok or Result.err')
        end
      end
    end
  end
end
# rubocop:enable RSpec/DescribedClass, Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
