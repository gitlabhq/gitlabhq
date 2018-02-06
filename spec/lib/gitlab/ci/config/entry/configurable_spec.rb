require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Configurable do
  let(:entry) do
    Class.new(Gitlab::Ci::Config::Entry::Node) do
      include Gitlab::Ci::Config::Entry::Configurable
    end
  end

  describe 'validations' do
    context 'when entry is a hash' do
      let(:instance) { entry.new(key: 'value') }

      it 'correctly validates an instance' do
        expect(instance).to be_valid
      end
    end

    context 'when entry is not a hash' do
      let(:instance) { entry.new('ls') }

      it 'invalidates the instance' do
        expect(instance).not_to be_valid
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
