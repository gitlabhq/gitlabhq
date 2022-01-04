# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::Configurable do
  let(:entry) do
    Class.new(Gitlab::Config::Entry::Node) do
      include Gitlab::Config::Entry::Configurable
    end
  end

  before do
    allow(entry).to receive(:default)
  end

  describe 'validations' do
    context 'when entry is a hash' do
      let(:instance) { entry.new({ key: 'value' }) }

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
    let(:entry_class) { double('entry_class', default: nil) }

    before do
      entry.class_exec(entry_class) do |entry_class|
        entry :object, entry_class,
          description: 'test object',
          inherit: true,
          reserved: true,
          deprecation: { deprecated: '10.0', warning: '10.1', removed: '11.0', documentation: 'docs.gitlab.com' }
      end
    end

    describe '.nodes' do
      it 'has valid nodes' do
        expect(entry.nodes).to include(:object)
      end

      it 'creates a node factory' do
        factory = entry.nodes[:object]

        expect(factory).to be_an_instance_of(Gitlab::Config::Entry::Factory)
        expect(factory.deprecation).to eq(
          deprecated: '10.0',
          warning: '10.1',
          removed: '11.0',
          documentation: 'docs.gitlab.com'
        )
        expect(factory.description).to eq('test object')
        expect(factory.inheritable?).to eq(true)
        expect(factory.reserved?).to eq(true)
      end

      it 'returns a duplicated factory object' do
        first_factory = entry.nodes[:object]
        second_factory = entry.nodes[:object]

        expect(first_factory).not_to be_equal(second_factory)
      end
    end

    describe '.reserved_node_names' do
      before do
        entry.class_exec(entry_class) do |entry_class|
          entry :not_reserved, entry_class
        end
      end

      it 'returns all nodes with reserved: true' do
        expect(entry.reserved_node_names).to contain_exactly(:object)
      end
    end
  end
end
