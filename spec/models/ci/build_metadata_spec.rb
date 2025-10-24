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
  let(:metadata) { create(:ci_build_metadata, build: job) }

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
        it 'rejects parallel.matrix missing required keys' do
          metadata.config_options = {
            script: ['echo'],
            parallel: {
              foo: 'bar'
            }
          }
          expect(metadata).to be_invalid
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
