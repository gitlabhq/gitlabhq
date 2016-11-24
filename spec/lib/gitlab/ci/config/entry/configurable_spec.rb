require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Configurable do
  let(:entry) { Class.new }

  before do
    entry.include(described_class)
  end

  describe 'validations' do
    let(:validator) { entry.validator.new(instance) }

    before do
      entry.class_eval do
        attr_reader :config

        def initialize(config)
          @config = config
        end
      end

      validator.validate
    end

    context 'when entry validator is invalid' do
      let(:instance) { entry.new('ls') }

      it 'returns invalid validator' do
        expect(validator).to be_invalid
      end
    end

    context 'when entry instance is valid' do
      let(:instance) { entry.new(key: 'value') }

      it 'returns valid validator' do
        expect(validator).to be_valid
      end
    end
  end

  describe 'configured entries' do
    before do
      entry.class_eval do
        entry :object, Object, description: 'test object'
      end
    end

    describe '.nodes' do
      it 'has valid nodes' do
        expect(entry.nodes).to include :object
      end

      it 'creates a node factory' do
        expect(entry.nodes[:object])
          .to be_an_instance_of Gitlab::Ci::Config::Entry::Factory
      end

      it 'returns a duplicated factory object' do
        first_factory = entry.nodes[:object]
        second_factory = entry.nodes[:object]

        expect(first_factory).not_to be_equal(second_factory)
      end
    end
  end
end
