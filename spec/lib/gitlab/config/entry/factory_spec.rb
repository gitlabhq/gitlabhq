# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::Factory do
  describe '#create!' do
    before do
      stub_const('Commands', Class.new(Gitlab::Config::Entry::Node))
      Commands.class_eval do
        include Gitlab::Config::Entry::Validatable

        validations do
          validates :config, array_of_strings: true
        end
      end
    end

    let(:entry) { Commands }
    let(:factory) { described_class.new(entry) }

    context 'when setting a concrete value' do
      it 'creates entry with valid value' do
        entry = factory
          .value(%w[ls pwd])
          .create!

        expect(entry.value).to eq %w[ls pwd]
      end

      context 'when setting description' do
        before do
          factory
            .value(%w[ls pwd])
            .with(description: 'test description')
        end

        it 'configures description' do
          expect(factory.description).to eq 'test description'
        end

        it 'creates entry with description' do
          entry = factory.create!

          expect(entry.value).to eq %w[ls pwd]
          expect(entry.description).to eq 'test description'
        end
      end

      context 'when setting inherit' do
        before do
          factory
            .value(%w[ls pwd])
            .with(inherit: true)
        end

        it 'makes object inheritable' do
          expect(factory.inheritable?).to eq true
        end
      end

      context 'when setting key' do
        it 'creates entry with custom key' do
          entry = factory
            .value(%w[ls pwd])
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
            .with(parent: object)
            .create!

          expect(entry.parent).to eq object
        end
      end
    end

    context 'when not setting a value' do
      it 'raises error' do
        expect { factory.create! }.to raise_error(
          Gitlab::Config::Entry::Factory::InvalidFactory
        )
      end
    end

    context 'when creating entry with nil value' do
      it 'creates an unspecified entry' do
        entry = factory
          .value(nil)
          .create!

        expect(entry)
          .not_to be_specified
      end
    end

    context 'when passing metadata' do
      let(:entry) { spy('entry') }

      it 'passes metadata as a parameter' do
        factory
          .value('some value')
          .metadata(some: 'hash')
          .create!

        expect(entry).to have_received(:new)
          .with('some value', { some: 'hash' })
      end
    end

    context 'when setting deprecation information' do
      it 'passes deprecation as a parameter' do
        entry = factory
           .value('some value')
           .with(deprecation: { deprecated: '10.0', warning: '10.1', removed: '11.0', documentation: 'docs' })
           .create!

        expect(entry.deprecation).to eq({ deprecated: '10.0', warning: '10.1', removed: '11.0', documentation: 'docs' })
      end
    end
  end
end
