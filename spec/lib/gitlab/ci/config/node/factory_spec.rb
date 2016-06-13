require 'spec_helper'

describe Gitlab::Ci::Config::Node::Factory do
  describe '#create!' do
    let(:factory) { described_class.new(entry_class) }
    let(:entry_class) { Gitlab::Ci::Config::Node::Script }

    context 'when value setting value' do
      it 'creates entry with valid value' do
        entry = factory
          .with(value: ['ls', 'pwd'])
          .create!

        expect(entry.value).to eq "ls\npwd"
      end

      context 'when setting description' do
        it 'creates entry with description' do
          entry = factory
            .with(value: ['ls', 'pwd'])
            .with(description: 'test description')
            .create!

          expect(entry.value).to eq "ls\npwd"
          expect(entry.description).to eq 'test description'
        end
      end
    end

    context 'when not setting value' do
      it 'raises error' do
        expect { factory.create! }.to raise_error(
          Gitlab::Ci::Config::Node::Factory::InvalidFactory
        )
      end
    end

    context 'when creating a null entry' do
      it 'creates a null entry' do
        entry = factory
          .with(value: nil)
          .nullify!
          .create!

        expect(entry).to be_an_instance_of Gitlab::Ci::Config::Node::Null
      end
    end
  end
end
