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

  describe '#update_timeout_state' do
    subject { metadata }

    shared_examples 'sets timeout' do |source, timeout|
      it 'sets project_timeout_source' do
        expect { subject.update_timeout_state }.to change { subject.reload.timeout_source }.to(source)
      end

      it 'sets project timeout' do
        expect { subject.update_timeout_state }.to change { subject.reload.timeout }.to(timeout)
      end
    end

    context 'when job, project and runner timeouts are set' do
      context 'when job timeout is lower then runner timeout' do
        before do
          runner.update!(maximum_timeout: 4000)
          job.update!(options: { job_timeout: 3000 })
        end

        it_behaves_like 'sets timeout', 'job_timeout_source', 3000
      end

      context 'when runner timeout is lower then job timeout' do
        before do
          runner.update!(maximum_timeout: 2000)
          job.update!(options: { job_timeout: 3000 })
        end

        it_behaves_like 'sets timeout', 'runner_timeout_source', 2000
      end
    end

    context 'when job, project timeout values are set and runner is assigned' do
      context 'when runner has no timeout set' do
        before do
          runner.update!(maximum_timeout: nil)
          job.update!(options: { job_timeout: 3000 })
        end

        it_behaves_like 'sets timeout', 'job_timeout_source', 3000
      end
    end

    context 'when only job and project timeouts are defined' do
      context 'when job timeout is lower then project timeout' do
        before do
          job.update!(options: { job_timeout: 1000 })
        end

        it_behaves_like 'sets timeout', 'job_timeout_source', 1000
      end

      context 'when project timeout is lower then job timeout' do
        before do
          job.update!(options: { job_timeout: 3000 })
        end

        it_behaves_like 'sets timeout', 'job_timeout_source', 3000
      end
    end

    context 'when only project and runner timeouts are defined' do
      before do
        runner.update!(maximum_timeout: 1900)
      end

      context 'when runner timeout is lower then project timeout' do
        it_behaves_like 'sets timeout', 'runner_timeout_source', 1900
      end

      context 'when project timeout is lower then runner timeout' do
        before do
          runner.update!(maximum_timeout: 2100)
        end

        it_behaves_like 'sets timeout', 'project_timeout_source', 2000
      end
    end

    context 'when only job and runner timeouts are defined' do
      context 'when runner timeout is lower them job timeout' do
        before do
          job.update!(options: { job_timeout: 2000 })
          runner.update!(maximum_timeout: 1900)
        end

        it_behaves_like 'sets timeout', 'runner_timeout_source', 1900
      end

      context 'when job timeout is lower them runner timeout' do
        before do
          job.update!(options: { job_timeout: 1000 })
          runner.update!(maximum_timeout: 1900)
        end

        it_behaves_like 'sets timeout', 'job_timeout_source', 1000
      end
    end

    context 'when only job timeout is defined and runner is assigned, but has no timeout set' do
      before do
        job.update!(options: { job_timeout: 1000 })
        runner.update!(maximum_timeout: nil)
      end

      it_behaves_like 'sets timeout', 'job_timeout_source', 1000
    end

    context 'when only one timeout value is defined' do
      context 'when only project timeout value is defined' do
        before do
          job.update!(options: { job_timeout: nil })
          runner.update!(maximum_timeout: nil)
        end

        it_behaves_like 'sets timeout', 'project_timeout_source', 2000
      end
    end
  end

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
  end

  describe 'set_cancel_gracefully' do
    it 'sets cancel_gracefully' do
      job.set_cancel_gracefully

      expect(job.cancel_gracefully?).to be true
    end

    it 'returns false' do
      expect(job.cancel_gracefully?).to be false
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
