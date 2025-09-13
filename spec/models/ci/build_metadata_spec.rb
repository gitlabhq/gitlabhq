# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildMetadata, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group, build_timeout: 2000) }
  let_it_be(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      sha: project.commit.id,
      ref: project.default_branch,
      status: 'success'
    )
  end

  let_it_be_with_reload(:runner) { create(:ci_runner) }

  let(:job) { create(:ci_build, pipeline: pipeline, runner: runner) }
  let(:metadata) { job.metadata }

  it_behaves_like 'having unique enum values'

  it { is_expected.to belong_to(:build) }
  it { is_expected.to belong_to(:project) }

  describe 'validations' do
    context 'when attributes are valid' do
      it 'returns no errors' do
        metadata.secrets = {
          DATABASE_PASSWORD: {
            vault: {
              engine: { name: 'kv-v2', path: 'kv-v2' },
              path: 'production/db',
              field: 'password'
            }
          }
        }
        metadata.id_tokens = {
          TEST_JWT_TOKEN: {
            aud: 'https://gitlab.test'
          }
        }

        expect(metadata).to be_valid
      end
    end

    context 'when data is invalid' do
      it 'returns errors' do
        metadata.secrets = { DATABASE_PASSWORD: { vault: {} } }
        metadata.id_tokens = { TEST_JWT_TOKEN: { id_token: { aud: nil } } }

        aggregate_failures do
          expect(metadata).to be_invalid
          expect(metadata.errors.full_messages).to contain_exactly(
            'Secrets must be a valid json schema',
            'Id tokens must be a valid json schema'
          )
        end
      end
    end

    describe 'config_options schema edge validation' do
      context 'with invalid edge cases' do
        it 'rejects non-string or object in services' do
          metadata.config_options = {
            script: ['echo "Hello"'],
            services: [123]
          }
          expect(metadata).to be_invalid
        end

        it 'rejects wrong type for reports.junit' do
          metadata.config_options = {
            script: ['echo'],
            artifacts: {
              reports: {
                junit: 123
              }
            }
          }
          expect(metadata).to be_invalid
        end

        it 'rejects missing coverage_format in coverage_report' do
          metadata.config_options = {
            script: ['echo'],
            artifacts: {
              reports: {
                coverage_report: {
                  path: 'coverage.xml'
                }
              }
            }
          }
          expect(metadata).to be_invalid
        end

        it 'rejects invalid environment.action enum value' do
          metadata.config_options = {
            script: ['echo'],
            environment: {
              name: 'production',
              action: 'launch'
            }
          }
          expect(metadata).to be_invalid
        end

        it 'rejects retry object missing required keys' do
          metadata.config_options = {
            script: ['echo'],
            retry: {
              when: ['script_failure']
            }
          }
          expect(metadata).to be_invalid
        end

        it 'rejects parallel.matrix missing required keys' do
          metadata.config_options = {
            script: ['echo'],
            parallel: {
              foo: 'bar'
            }
          }
          expect(metadata).to be_invalid
        end

        it 'rejects bridge_needs missing required keys' do
          metadata.config_options = {
            script: ['echo'],
            bridge_needs: {
              artifacts: true
            }
          }
          expect(metadata).to be_invalid
        end

        it 'rejects invalid image format' do
          metadata.config_options = {
            script: ['echo'],
            image: { entrypoint: ['/bin/bash'] }
          }
          expect(metadata).to be_invalid
        end

        it 'rejects artifacts when paths is not an array' do
          metadata.config_options = {
            script: ['echo'],
            artifacts: {
              paths: 'not-an-array'
            }
          }
          expect(metadata).to be_invalid
        end

        it 'rejects allow_failure_criteria with wrong exit_codes type' do
          metadata.config_options = {
            script: ['echo'],
            allow_failure_criteria: {
              exit_codes: 'not-an-integer-or-array'
            }
          }
          expect(metadata).to be_invalid
        end

        it 'rejects invalid hooks' do
          metadata.config_options = {
            script: ['echo'],
            hooks: {
              pre_get_sources_script: 'not-an-array'
            }
          }
          expect(metadata).to be_invalid
        end
      end

      context 'when ci_validate_config_options feature flag is disabled' do
        before do
          stub_feature_flags(ci_validate_config_options: false)
        end

        context 'with invalid edge cases' do
          it 'does not validate when feature flag is disabled' do
            metadata.config_options = {
              script: ['echo "Hello"'],
              services: [123]
            }

            expect(metadata).to be_valid
            expect(metadata.errors[:config_options]).to be_empty
          end

          it 'accepts invalid artifacts structure' do
            metadata.config_options = {
              script: ['echo'],
              artifacts: {
                paths: 'not-an-array'
              }
            }

            expect(metadata).to be_valid
          end
        end
      end
    end

    describe '#validate_config_options_schema logging and error behavior' do
      let(:invalid_options) do
        {
          script: ['echo'],
          services: '123'
        }
      end

      let(:valid_options) do
        {
          script: ['echo'],
          services: [123]
        }
      end

      context 'when ci_validate_config_options feature flag is disabled' do
        before do
          stub_feature_flags(ci_validate_config_options: false)
        end

        it 'does not log warnings' do
          metadata.config_options = valid_options

          expect(Gitlab::AppJsonLogger).not_to receive(:warn)

          expect(metadata).to be_valid
        end

        it 'does not raise errors in production' do
          allow(Rails.env).to receive(:production?).and_return(true)
          metadata.config_options = invalid_options

          expect(metadata).to be_valid
        end
      end
    end
  end

  context 'loose foreign key on ci_builds_metadata.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { project }
      let!(:model) { metadata }
    end
  end

  describe '#enable_debug_trace!' do
    subject { metadata.enable_debug_trace! }

    context 'when debug_trace_enabled is false' do
      it 'sets debug_trace_enabled to true' do
        subject

        expect(metadata.debug_trace_enabled).to eq(true)
      end
    end

    context 'when debug_trace_enabled is true' do
      before do
        metadata.update!(debug_trace_enabled: true)
      end

      it 'does not set debug_trace_enabled to true', :aggregate_failures do
        expect(described_class).not_to receive(:save!)
        expect(metadata.debug_trace_enabled).to eq(true)
      end
    end
  end

  describe 'partitioning' do
    context 'with job' do
      let(:status) { build(:commit_status, partition_id: 123) }
      let(:metadata) { build(:ci_build_metadata, build: status) }

      it 'copies the partition_id from job' do
        expect { metadata.valid? }.to change(metadata, :partition_id).to(123)
      end

      context 'when it is already set' do
        let(:metadata) { build(:ci_build_metadata, build: status, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { metadata.valid? }.not_to change(metadata, :partition_id)
        end
      end
    end

    context 'without job' do
      subject(:metadata) do
        build(:ci_build_metadata, build: nil)
      end

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { metadata.valid? }.not_to change(metadata, :partition_id)
      end
    end
  end

  context 'jsonb fields serialization' do
    it 'changing other fields does not change config_options' do
      expect { metadata.id = metadata.id }.not_to change(metadata, :changes)
    end

    it 'accessing config_options does not change it' do
      expect { metadata.config_options }.not_to change(metadata, :changes)
    end
  end
end
