# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::Validators do
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
          expect(instance.errors.messages_for(:config)).to include /please use only one the following keys: foo, bar/
        end
      end
    end
  end
end
