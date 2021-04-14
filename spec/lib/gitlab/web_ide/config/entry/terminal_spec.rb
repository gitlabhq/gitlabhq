# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WebIde::Config::Entry::Terminal do
  let(:entry) { described_class.new(config, with_image_ports: true) }

  describe '.nodes' do
    context 'when filtering all the entry/node names' do
      subject { described_class.nodes.keys }

      let(:result) do
        %i[before_script script image services variables]
      end

      it { is_expected.to match_array result }
    end
  end

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { { script: 'rspec' } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when the same port is not duplicated' do
        let(:config) do
          {
            image: { name: "ruby", ports: [80] },
            services: [{ name: "mysql", alias: "service1", ports: [81] }, { name: "mysql", alias: "service2", ports: [82] }]
          }
        end

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end

      context 'when unknown port keys detected' do
        let(:config) do
          {
            image: { name: "ruby", ports: [80] },
            services: [{ name: "mysql", alias: "service2", ports: [{ number: 81, invalid_key: 'foobar' }] }]
          }
        end

        it 'is not valid' do
          expect(entry).not_to be_valid
          expect(entry.errors.first)
            .to match /port config contains unknown keys: invalid_key/
        end
      end
    end

    context 'when entry value is not correct' do
      context 'incorrect config value type' do
        let(:config) { ['incorrect'] }

        describe '#errors' do
          it 'reports error about a config type' do
            expect(entry.errors)
              .to include 'terminal config should be a hash'
          end
        end
      end

      context 'when config is empty' do
        let(:config) { {} }

        describe '#valid' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end

      context 'when unknown keys detected' do
        let(:config) { { unknown: true } }

        describe '#valid' do
          it 'is not valid' do
            expect(entry).not_to be_valid
          end
        end
      end

      context 'when the same port is duplicated' do
        let(:config) do
          {
            image: { name: "ruby", ports: [80] },
            services: [{ name: "mysql", ports: [80] }, { name: "mysql", ports: [81] }]
          }
        end

        describe '#valid?' do
          it 'is invalid' do
            expect(entry).not_to be_valid
            expect(entry.errors.count).to eq 1
            expect(entry.errors.first).to match "each port number can only be referenced once"
          end
        end
      end
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      entry = described_class.new({ script: 'rspec' })

      expect(entry).to be_relevant
    end
  end

  context 'when composed' do
    before do
      entry.compose!
    end

    describe '#value' do
      context 'when entry is correct' do
        let(:config) do
          { before_script: %w[ls pwd],
            script: 'sleep 100',
            tags: ['webide'],
            image: 'ruby:3.0',
            services: ['mysql'],
            variables: { KEY: 'value' } }
        end

        it 'returns correct value' do
          expect(entry.value)
            .to eq(
              tag_list: ['webide'],
              yaml_variables: [{ key: 'KEY', value: 'value', public: true }],
              job_variables: [{ key: 'KEY', value: 'value', public: true }],
              options: {
                image: { name: "ruby:3.0" },
                services: [{ name: "mysql" }],
                before_script: %w[ls pwd],
                script: ['sleep 100']
              }
            )
        end
      end
    end
  end
end
