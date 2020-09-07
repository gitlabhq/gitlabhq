# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildMetadata do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group, build_timeout: 2000) }

  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:metadata) { build.metadata }

  it_behaves_like 'having unique enum values'

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

    context 'when project timeout is set' do
      context 'when runner is assigned to the job' do
        before do
          build.update!(runner: runner)
        end

        context 'when runner timeout is not set' do
          let(:runner) { create(:ci_runner, maximum_timeout: nil) }

          it_behaves_like 'sets timeout', 'project_timeout_source', 2000
        end

        context 'when runner timeout is lower than project timeout' do
          let(:runner) { create(:ci_runner, maximum_timeout: 1900) }

          it_behaves_like 'sets timeout', 'runner_timeout_source', 1900
        end

        context 'when runner timeout is higher than project timeout' do
          let(:runner) { create(:ci_runner, maximum_timeout: 2100) }

          it_behaves_like 'sets timeout', 'project_timeout_source', 2000
        end
      end

      context 'when job timeout is set' do
        context 'when job timeout is higher than project timeout' do
          let(:build) { create(:ci_build, pipeline: pipeline, options: { job_timeout: 3000 }) }

          it_behaves_like 'sets timeout', 'job_timeout_source', 3000
        end

        context 'when job timeout is lower than project timeout' do
          let(:build) { create(:ci_build, pipeline: pipeline, options: { job_timeout: 1000 }) }

          it_behaves_like 'sets timeout', 'job_timeout_source', 1000
        end
      end

      context 'when both runner and job timeouts are set' do
        before do
          build.update!(runner: runner)
        end

        context 'when job timeout is higher than runner timeout' do
          let(:build) { create(:ci_build, pipeline: pipeline, options: { job_timeout: 3000 }) }
          let(:runner) { create(:ci_runner, maximum_timeout: 2100) }

          it_behaves_like 'sets timeout', 'runner_timeout_source', 2100
        end

        context 'when job timeout is lower than runner timeout' do
          let(:build) { create(:ci_build, pipeline: pipeline, options: { job_timeout: 1900 }) }
          let(:runner) { create(:ci_runner, maximum_timeout: 2100) }

          it_behaves_like 'sets timeout', 'job_timeout_source', 1900
        end
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

        expect(metadata).to be_valid
      end
    end

    context 'when data is invalid' do
      it 'returns errors' do
        metadata.secrets = { DATABASE_PASSWORD: { vault: {} } }

        aggregate_failures do
          expect(metadata).to be_invalid
          expect(metadata.errors.full_messages).to eq(["Secrets must be a valid json schema"])
        end
      end
    end
  end
end
