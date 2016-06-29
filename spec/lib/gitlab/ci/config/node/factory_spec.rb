require 'spec_helper'

describe Gitlab::Ci::Config::Node::Factory do
  describe '#create!' do
    let(:factory) { described_class.new(entry_class) }
    let(:entry_class) { Gitlab::Ci::Config::Node::Script }

    context 'when setting up a value' do
      it 'creates entry with valid value' do
        entry = factory
          .with(value: ['ls', 'pwd'])
          .create!

        expect(entry.value).to eq ['ls', 'pwd']
      end

      context 'when setting description' do
        it 'creates entry with description' do
          entry = factory
            .with(value: ['ls', 'pwd'])
            .with(description: 'test description')
            .create!

          expect(entry.value).to eq ['ls', 'pwd']
          expect(entry.description).to eq 'test description'
        end
      end

      context 'when setting key' do
        it 'creates entry with custom key' do
          entry = factory
            .with(value: ['ls', 'pwd'], key: 'test key')
            .create!

          expect(entry.key).to eq 'test key'
        end
      end

      context 'when setting a parent' do
        let(:parent) { Object.new }

        it 'creates entry with valid parent' do
          entry = factory
            .with(value: 'ls', parent: parent)
            .create!

          expect(entry.parent).to eq parent
        end
      end
    end

    context 'when not setting up a value' do
      it 'raises error' do
        expect { factory.create! }.to raise_error(
          Gitlab::Ci::Config::Node::Factory::InvalidFactory
        )
      end
    end

    context 'when creating entry with nil value' do
      it 'creates an undefined entry' do
        entry = factory
          .with(value: nil)
          .create!

        expect(entry).to be_an_instance_of Gitlab::Ci::Config::Node::Undefined
      end
    end
  end
end
