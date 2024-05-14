# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Ports do
  let(:entry) { described_class.new(config) }

  before do
    entry.compose!
  end

  context 'when configuration is valid' do
    let(:config) { [{ number: 80, protocol: 'http', name: 'foobar' }] }

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#value' do
      it 'returns valid array' do
        expect(entry.value).to eq(config)
      end
    end
  end

  context 'when configuration is invalid' do
    let(:config) { 'postgresql:9.5' }

    describe '#valid?' do
      it 'is invalid' do
        expect(entry).not_to be_valid
      end
    end

    context 'when any of the ports' do
      before do
        expect(entry).not_to be_valid
        expect(entry.errors.count).to eq 1
      end

      context 'have the same name' do
        let(:config) do
          [{ number: 80, protocol: 'http', name: 'foobar' },
           { number: 81, protocol: 'http', name: 'foobar' }]
        end

        describe '#valid?' do
          it 'is invalid' do
            expect(entry.errors.first).to match(/each port name must be different/)
          end
        end
      end

      context 'have the same port' do
        let(:config) do
          [{ number: 80, protocol: 'http', name: 'foobar' },
           { number: 80, protocol: 'http', name: 'foobar1' }]
        end

        describe '#valid?' do
          it 'is invalid' do
            expect(entry.errors.first).to match(/each port number can only be referenced once/)
          end
        end
      end
    end
  end
end
