require 'spec_helper'

describe Gitlab::Ci::Config::Node::Factory do
  describe '#create!' do
    let(:factory) { described_class.new(node) }
    let(:node) { Gitlab::Ci::Config::Node::Script }
    let(:parent) { double('parent') }
    let(:global) { double('global') }

    before do
      allow(parent).to receive(:global).and_return(global)
    end

    context 'when setting a concrete value' do
      it 'creates entry with valid value' do
        entry = factory
          .value(['ls', 'pwd'])
          .parent(parent)
          .create!

        expect(entry.value).to eq ['ls', 'pwd']
      end

      it 'sets parent and global attributes' do
        entry = factory
          .value('ls')
          .parent(parent)
          .create!

        expect(entry.global).to eq global
        expect(entry.parent).to eq parent
      end

      context 'when setting description' do
        it 'creates entry with description' do
          entry = factory
            .value(['ls', 'pwd'])
            .parent(parent)
            .with(description: 'test description')
            .create!

          expect(entry.value).to eq ['ls', 'pwd']
          expect(entry.description).to eq 'test description'
        end
      end

      context 'when setting key' do
        it 'creates entry with custom key' do
          entry = factory
            .value(['ls', 'pwd'])
            .parent(parent)
            .with(key: 'test key')
            .create!

          expect(entry.key).to eq 'test key'
        end
      end

      context 'when setting a parent' do
        let(:object) { Object.new }

        it 'creates entry with valid parent' do
          entry = factory
            .value('ls')
            .parent(parent)
            .with(parent: object)
            .create!

          expect(entry.parent).to eq object
        end
      end
    end

    context 'when not setting a value' do
      it 'raises error' do
        expect { factory.create! }.to raise_error(
          Gitlab::Ci::Config::Node::Factory::InvalidFactory
        )
      end
    end

    context 'when not setting parent object' do
      it 'raises error' do
        expect { factory.value('ls').create! }.to raise_error(
          Gitlab::Ci::Config::Node::Factory::InvalidFactory
        )
      end
    end

    context 'when creating entry with nil value' do
      it 'creates an undefined entry' do
        entry = factory
          .value(nil)
          .parent(parent)
          .create!

        expect(entry).to be_an_instance_of Gitlab::Ci::Config::Node::Undefined
      end
    end
  end
end
