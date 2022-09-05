# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Port do
  let(:entry) { described_class.new(config) }

  before do
    entry.compose!
  end

  context 'when configuration is a string' do
    let(:config) { 80 }

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#value' do
      it 'returns valid hash' do
        expect(entry.value).to eq(number: 80)
      end
    end

    describe '#number' do
      it "returns port number" do
        expect(entry.number).to eq 80
      end
    end

    describe '#protocol' do
      it "is nil" do
        expect(entry.protocol).to be_nil
      end
    end

    describe '#name' do
      it "is nil" do
        expect(entry.name).to be_nil
      end
    end
  end

  context 'when configuration is a hash' do
    context 'with the complete hash' do
      let(:config) do
        { number: 80,
          protocol: 'http',
          name: 'foobar' }
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      describe '#value' do
        it 'returns valid hash' do
          expect(entry.value).to eq config
        end
      end

      describe '#number' do
        it "returns port number" do
          expect(entry.number).to eq 80
        end
      end

      describe '#protocol' do
        it "returns port protocol" do
          expect(entry.protocol).to eq 'http'
        end
      end

      describe '#name' do
        it "returns port name" do
          expect(entry.name).to eq 'foobar'
        end
      end
    end

    context 'with only the port number' do
      let(:config) { { number: 80 } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      describe '#value' do
        it 'returns valid hash' do
          expect(entry.value).to eq(number: 80)
        end
      end

      describe '#number' do
        it "returns port number" do
          expect(entry.number).to eq 80
        end
      end

      describe '#protocol' do
        it "is nil" do
          expect(entry.protocol).to be_nil
        end
      end

      describe '#name' do
        it "is nil" do
          expect(entry.name).to be_nil
        end
      end
    end

    context 'without the number' do
      let(:config) { { protocol: 'http' } }

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end
    end
  end

  context 'when configuration is invalid' do
    let(:config) { '80' }

    describe '#valid?' do
      it 'is valid' do
        expect(entry).not_to be_valid
      end
    end
  end

  context 'when protocol' do
    let(:config) { { number: 80, protocol: protocol, name: 'foobar' } }

    context 'is http' do
      let(:protocol) { 'http' }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'is https' do
      let(:protocol) { 'https' }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'is neither http nor https' do
      let(:protocol) { 'foo' }

      describe '#valid?' do
        it 'is invalid' do
          expect(entry.errors).to include("port protocol should be http or https")
        end
      end
    end
  end
end
