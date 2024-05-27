# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Config::Entry::Simplifiable do
  describe '.strategy' do
    let(:entry) do
      Class.new(described_class) do
        strategy :Something, if: -> { 'condition' }
        strategy :DifferentOne, if: -> { 'condition' }
      end
    end

    it 'defines entry strategies' do
      expect(entry.strategies.size).to eq 2
      expect(entry.strategies.map(&:name))
        .to eq %i[Something DifferentOne]
    end
  end

  describe 'setting strategy by a condition' do
    let(:first) { double('first strategy') }
    let(:second) { double('second strategy') }
    let(:unknown) { double('unknown strategy') }

    before do
      entry::Something = first
      entry::DifferentOne = second
      entry::UnknownStrategy = unknown
    end

    context 'when first strategy should be used' do
      let(:entry) do
        Class.new(described_class) do
          strategy :Something, if: ->(arg) { arg == 'something' }
          strategy :DifferentOne, if: ->(*) { false }
        end
      end

      it 'attemps to load a first strategy' do
        expect(first).to receive(:new).with('something')

        entry.new('something')
      end
    end

    context 'when second strategy should be used' do
      let(:entry) do
        Class.new(described_class) do
          strategy :Something, if: ->(arg) { arg == 'something' }
          strategy :DifferentOne, if: ->(arg) { arg == 'test' }
        end
      end

      it 'attemps to load a second strategy' do
        expect(second).to receive(:new).with('test')

        entry.new('test')
      end
    end

    context 'when neither one is a valid strategy' do
      let(:entry) do
        Class.new(described_class) do
          strategy :Something, if: ->(*) { false }
          strategy :DifferentOne, if: ->(*) { false }
        end
      end

      it 'instantiates an unknown strategy' do
        expect(unknown).to receive(:new).with('test')

        entry.new('test')
      end
    end
  end

  context 'when a unknown strategy class is not defined' do
    let(:entry) do
      Class.new(described_class) do
        strategy :String, if: ->(*) { true }
      end
    end

    it 'raises an error when being initialized' do
      expect { entry.new('something') }
        .to raise_error ArgumentError, /UndefinedStrategy not available!/
    end
  end
end
