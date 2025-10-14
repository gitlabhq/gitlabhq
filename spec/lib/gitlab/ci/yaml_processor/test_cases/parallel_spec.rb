# frozen_string_literal: true

require 'spec_helper'

module Gitlab
  module Ci
    RSpec.describe YamlProcessor, feature_category: :pipeline_composition do
      let_it_be(:project) { create(:project, :repository) }

      subject(:processor) do
        described_class.new(config, project: project, user: project.first_owner)
      end

      context 'when using needs:parallel:matrix' do
        context 'when using matrix expressions' do
          let(:config) do
            <<~YAML
            build:
              script: echo build
              parallel:
                matrix:
                  - OS: [linux]
                    ARCH: [amd64, arm64]

            test:
              script: echo test
              parallel:
                matrix:
                  - OS: [linux]
                    ARCH: [amd64, arm64]
              needs:
                - job: build
                  parallel:
                    matrix:
                      - OS: ['$[[ matrix.OS ]]']
                        ARCH: ['$[[ matrix.ARCH ]]']
            YAML
          end

          it 'processes matrix expressions successfully' do
            result = processor.execute
            builds = result.builds

            expect(result.errors).to be_empty

            # Should have 4 builds: 2 build jobs + 2 test jobs
            expect(builds.size).to be(4)

            test_amd64 = builds.find { |b| b[:name] == 'test: [linux, amd64]' }
            test_arm64 = builds.find { |b| b[:name] == 'test: [linux, arm64]' }

            expect(test_amd64[:needs_attributes]).to contain_exactly(
              { name: 'build: [linux, amd64]', artifacts: true, optional: false }
            )
            expect(test_arm64[:needs_attributes]).to contain_exactly(
              { name: 'build: [linux, arm64]', artifacts: true, optional: false }
            )
          end

          context 'when matrix expressions reference non-existent values' do
            let(:config) do
              <<~YAML
              build:
                script: echo build
                parallel:
                  matrix:
                    - OS: [linux]
                      ARCH: [amd64, arm64]

              test:
                script: echo test
                parallel:
                  matrix:
                    - OS: [linux]
                      ARCH: [amd64, arm64]
                needs:
                  - job: build
                    parallel:
                      matrix:
                        - OS: ['$[[ matrix.OS ]]']
                          MISSING: ['$[[ matrix.NONEXISTENT ]]']
              YAML
            end

            it 'returns validation error for missing matrix value' do
              result = processor.execute

              expect(result.errors).to contain_exactly(
                "test job: 'NONEXISTENT' does not exist in matrix configuration"
              )
            end
          end

          context 'when ci_matrix_expressions feature flag is disabled' do
            before do
              stub_feature_flags(ci_matrix_expressions: false)
            end

            it 'returns an error for invalid job reference' do
              result = processor.execute

              expect(result.errors).to contain_exactly(
                a_string_including('undefined need: build: [$[[ matrix.OS ]], $[[ matrix.ARCH ]]]')
              )
            end
          end
        end
      end
    end
  end
end
