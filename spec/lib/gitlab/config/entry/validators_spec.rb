# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::Validators, feature_category: :pipeline_composition do
  let(:klass) do
    Class.new do
      include ActiveModel::Validations
      include Gitlab::Config::Entry::Validators
    end
  end

  let(:instance) { klass.new }

  describe described_class::MutuallyExclusiveKeysValidator do
    using RSpec::Parameterized::TableSyntax

    before do
      klass.instance_eval do
        validates :config, mutually_exclusive_keys: [:foo, :bar]
      end

      allow(instance).to receive(:config).and_return(config)
    end

    where(:context, :config, :valid_result) do
      'with mutually exclusive keys' | { foo: 1, bar: 2 } | false
      'without mutually exclusive keys' | { foo: 1 } | true
      'without mutually exclusive keys' | { bar: 1 } | true
      'with other keys' | { foo: 1, baz: 2 } | true
    end

    with_them do
      it 'validates the instance' do
        expect(instance.valid?).to be(valid_result)

        unless valid_result
          expect(instance.errors.messages_for(:config)).to include(/these keys cannot be used together: foo, bar/)
        end
      end
    end
  end

  describe described_class::DisallowedKeysValidator do
    using RSpec::Parameterized::TableSyntax

    where(:config, :disallowed_keys, :ignore_nil, :valid_result) do
      { foo: '1' }                     | 'foo'      | false | false
      { foo: '1', bar: '2', baz: '3' } | 'foo, bar' | false | false
      { baz: '1', qux: '2' }           | ''         | false | true
      { foo: nil }                     | 'foo'      | false | false
      { foo: nil, bar: '2', baz: '3' } | 'foo, bar' | false | false
      { foo: nil, bar: nil, baz: '3' } | 'foo, bar' | false | false
      { baz: nil, qux: nil }           | ''         | false | true
      { foo: '1' }                     | 'foo'      | true  | false
      { foo: '1', bar: '2', baz: '3' } | 'foo, bar' | true  | false
      { baz: '1', qux: '2' }           | ''         | true  | true
      { foo: nil }                     | ''         | true  | true
      { foo: nil, bar: '2', baz: '3' } | 'bar'      | true  | false
      { foo: nil, bar: nil, baz: '3' } | ''         | true  | true
      { baz: nil, qux: nil }           | ''         | true  | true
    end

    with_them do
      before do
        klass.instance_variable_set(:@ignore_nil, ignore_nil)

        klass.instance_eval do
          validates :config, disallowed_keys: {
            in: %i[foo bar],
            ignore_nil: @ignore_nil # rubocop:disable RSpec/InstanceVariable
          }
        end

        allow(instance).to receive(:config).and_return(config)
      end

      it 'validates the instance' do
        expect(instance.valid?).to be(valid_result)

        unless valid_result
          expect(instance.errors.messages_for(:config)).to include "contains disallowed keys: #{disallowed_keys}"
        end
      end
    end

    context 'when custom message is provided' do
      before do
        klass.instance_eval do
          validates :config, disallowed_keys: {
            in: %i[foo bar],
            message: 'custom message'
          }
        end

        allow(instance).to receive(:config).and_return({ foo: '1' })
      end

      it 'returns the custom message when invalid' do
        expect(instance).not_to be_valid
        expect(instance.errors.messages_for(:config)).to include "custom message: foo"
      end
    end
  end

  describe described_class::OnlyOneOfKeysValidator do
    using RSpec::Parameterized::TableSyntax

    where(:config, :valid_result) do
      { foo: '1' }                     | true
      { foo: '1', bar: '2', baz: '3' } | false
      { bar: '2' }                     | true
      { foo: '1' }                     | true
      {}                               | false
      { baz: '3' }                     | false
    end

    with_them do
      before do
        klass.instance_eval do
          validates :config, only_one_of_keys: %i[foo bar]
        end

        allow(instance).to receive(:config).and_return(config)
      end

      it 'validates the instance' do
        expect(instance.valid?).to be(valid_result)

        unless valid_result
          expect(instance.errors.messages_for(:config)).to(
            include "must use exactly one of these keys: foo, bar"
          )
        end
      end
    end
  end

  describe described_class::ScalarValidator do
    using RSpec::Parameterized::TableSyntax

    where(:config, :valid_result) do
      'string' | true
      :symbol  | true
      true     | true
      false    | true
      2        | true
      2.2      | true
      []       | false
      {}       | false
    end

    with_them do
      before do
        klass.instance_eval do
          validates :config, scalar: %i[foo bar]
        end

        allow(instance).to receive(:config).and_return(config)
      end

      it 'validates the instance' do
        expect(instance.valid?).to be(valid_result)
        expect(instance.errors.messages_for(:config)).to contain_exactly('must be a scalar') unless valid_result
      end
    end
  end
end
