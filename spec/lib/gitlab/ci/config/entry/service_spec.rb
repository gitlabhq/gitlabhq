# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Service do
  let(:entry) { described_class.new(config) }

  before do
    entry.compose!
  end

  context 'when configuration is a string' do
    let(:config) { 'postgresql:9.5' }

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end

    describe '#value' do
      it 'returns valid hash' do
        expect(entry.value).to include(name: 'postgresql:9.5')
      end
    end

    describe '#image' do
      it "returns service's image name" do
        expect(entry.name).to eq 'postgresql:9.5'
      end
    end

    describe '#alias' do
      it "returns service's alias" do
        expect(entry.alias).to be_nil
      end
    end

    describe '#command' do
      it "returns service's command" do
        expect(entry.command).to be_nil
      end
    end

    describe '#ports' do
      it "returns service's ports" do
        expect(entry.ports).to be_nil
      end
    end
  end

  context 'when configuration is a hash' do
    let(:config) do
      { name: 'postgresql:9.5', alias: 'db', command: %w(cmd run), entrypoint: %w(/bin/sh run) }
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

    describe '#image' do
      it "returns service's image name" do
        expect(entry.name).to eq 'postgresql:9.5'
      end
    end

    describe '#alias' do
      it "returns service's alias" do
        expect(entry.alias).to eq 'db'
      end
    end

    describe '#command' do
      it "returns service's command" do
        expect(entry.command).to eq %w(cmd run)
      end
    end

    describe '#entrypoint' do
      it "returns service's entrypoint" do
        expect(entry.entrypoint).to eq %w(/bin/sh run)
      end
    end

    context 'when configuration has ports' do
      let(:ports) { [{ number: 80, protocol: 'http', name: 'foobar' }] }
      let(:config) do
        { name: 'postgresql:9.5', alias: 'db', command: %w(cmd run), entrypoint: %w(/bin/sh run), ports: ports }
      end
      let(:entry) { described_class.new(config, { with_image_ports: image_ports }) }
      let(:image_ports) { false }

      context 'when with_image_ports metadata is not enabled' do
        describe '#valid?' do
          it 'is not valid' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include("service config contains disallowed keys: ports")
          end
        end
      end

      context 'when with_image_ports metadata is enabled' do
        let(:image_ports) { true }

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end

          context 'when unknown port keys detected' do
            let(:ports) { [{ number: 80, invalid_key: 'foo' }] }

            it 'is not valid' do
              expect(entry).not_to be_valid
              expect(entry.errors.first)
                .to match /port config contains unknown keys: invalid_key/
            end
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
    let(:config) { ['postgresql:9.5'] }

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
    let(:config) { { name: 'postgresql:9.5', non_existing: 'test' } }

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

  context 'when service has ports' do
    let(:ports) { [{ number: 80, protocol: 'http', name: 'foobar' }] }
    let(:config) do
      { name: 'postgresql:9.5', command: %w(cmd run), entrypoint: %w(/bin/sh run), ports: ports }
    end

    it 'alias field is mandatory' do
      expect(entry).not_to be_valid
      expect(entry.errors).to include("service alias can't be blank")
    end
  end

  context 'when service does not have ports' do
    let(:config) do
      { name: 'postgresql:9.5', alias: 'db', command: %w(cmd run), entrypoint: %w(/bin/sh run) }
    end

    it 'alias field is optional' do
      expect(entry).to be_valid
    end
  end
end
