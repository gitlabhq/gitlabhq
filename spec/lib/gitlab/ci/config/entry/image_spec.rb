# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Image do
  let(:entry) { described_class.new(config) }

  context 'when configuration is a string' do
    let(:config) { 'ruby:2.7' }

    describe '#value' do
      it 'returns image hash' do
        expect(entry.value).to eq({ name: 'ruby:2.7' })
      end
    end

    describe '#errors' do
      it 'does not append errors' do
        expect(entry.errors).to be_empty
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#image' do
      it "returns image's name" do
        expect(entry.name).to eq 'ruby:2.7'
      end
    end

    describe '#entrypoint' do
      it "returns image's entrypoint" do
        expect(entry.entrypoint).to be_nil
      end
    end

    describe '#ports' do
      it "returns image's ports" do
        expect(entry.ports).to be_nil
      end
    end
  end

  context 'when configuration is a hash' do
    let(:config) { { name: 'ruby:2.7', entrypoint: %w(/bin/sh run) } }

    describe '#value' do
      it 'returns image hash' do
        expect(entry.value).to eq(config)
      end
    end

    describe '#errors' do
      it 'does not append errors' do
        expect(entry.errors).to be_empty
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#image' do
      it "returns image's name" do
        expect(entry.name).to eq 'ruby:2.7'
      end
    end

    describe '#entrypoint' do
      it "returns image's entrypoint" do
        expect(entry.entrypoint).to eq %w(/bin/sh run)
      end
    end

    context 'when configuration has ports' do
      let(:ports) { [{ number: 80, protocol: 'http', name: 'foobar' }] }
      let(:config) { { name: 'ruby:2.7', entrypoint: %w(/bin/sh run), ports: ports } }
      let(:entry) { described_class.new(config, with_image_ports: image_ports) }
      let(:image_ports) { false }

      context 'when with_image_ports metadata is not enabled' do
        describe '#valid?' do
          it 'is not valid' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include("image config contains disallowed keys: ports")
          end
        end
      end

      context 'when with_image_ports metadata is enabled' do
        let(:image_ports) { true }

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end

        describe '#ports' do
          it "returns image's ports" do
            expect(entry.ports).to eq ports
          end
        end
      end
    end
  end

  context 'when entry value is not correct' do
    let(:config) { ['ruby:2.7'] }

    describe '#errors' do
      it 'saves errors' do
        expect(entry.errors.first)
          .to match /config should be a hash or a string/
      end
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end
  end

  context 'when unexpected key is specified' do
    let(:config) { { name: 'ruby:2.7', non_existing: 'test' } }

    describe '#errors' do
      it 'saves errors' do
        expect(entry.errors.first)
          .to match /config contains unknown keys: non_existing/
      end
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end
  end
end
