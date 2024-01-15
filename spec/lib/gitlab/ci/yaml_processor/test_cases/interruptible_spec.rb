# frozen_string_literal: true

require 'spec_helper'

module Gitlab
  module Ci
    RSpec.describe YamlProcessor, feature_category: :pipeline_composition do
      subject(:processor) { described_class.new(config, user: nil) }

      let(:result) { processor.execute }
      let(:builds) { result.builds }

      context 'with interruptible' do
        let(:default_config) { nil }

        let(:config) do
          <<~YAML
            #{default_config}

            build1:
              script: rspec
              interruptible: true

            build2:
              script: rspec
              interruptible: false

            build3:
              script: rspec

            bridge1:
              trigger: some/project
              interruptible: true

            bridge2:
              trigger: some/project
              interruptible: false

            bridge3:
              trigger: some/project
          YAML
        end

        it 'returns jobs with their interruptible value' do
          expect(builds).to contain_exactly(
            a_hash_including(name: 'build1', interruptible: true),
            a_hash_including(name: 'build2', interruptible: false),
            a_hash_including(name: 'build3').and(exclude(:interruptible)),
            a_hash_including(name: 'bridge1', interruptible: true),
            a_hash_including(name: 'bridge2', interruptible: false),
            a_hash_including(name: 'bridge3').and(exclude(:interruptible))
          )
        end

        context 'when default:interruptible is true' do
          let(:default_config) do
            <<~YAML
              default:
                interruptible: true
            YAML
          end

          it 'returns jobs with their interruptible value' do
            expect(builds).to contain_exactly(
              a_hash_including(name: 'build1', interruptible: true),
              a_hash_including(name: 'build2', interruptible: false),
              a_hash_including(name: 'build3', interruptible: true),
              a_hash_including(name: 'bridge1', interruptible: true),
              a_hash_including(name: 'bridge2', interruptible: false),
              a_hash_including(name: 'bridge3', interruptible: true)
            )
          end
        end

        context 'when default:interruptible is false' do
          let(:default_config) do
            <<~YAML
              default:
                interruptible: false
            YAML
          end

          it 'returns jobs with their interruptible value' do
            expect(builds).to contain_exactly(
              a_hash_including(name: 'build1', interruptible: true),
              a_hash_including(name: 'build2', interruptible: false),
              a_hash_including(name: 'build3', interruptible: false),
              a_hash_including(name: 'bridge1', interruptible: true),
              a_hash_including(name: 'bridge2', interruptible: false),
              a_hash_including(name: 'bridge3', interruptible: false)
            )
          end
        end
      end
    end
  end
end
