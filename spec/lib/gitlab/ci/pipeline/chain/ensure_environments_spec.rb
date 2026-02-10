# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::EnsureEnvironments, :aggregate_failures do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:ref) { 'master' }
  let(:stage) { build(:ci_stage, project: project, statuses: [job]) }
  let(:pipeline) { build(:ci_pipeline, project: project, ref: ref, stages: [stage]) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:environment) { project.environments.find_by_name("review/#{ref}") }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    subject { step.perform! }

    before do
      job.pipeline = pipeline
    end

    context 'when a pipeline contains a deployment job' do
      let!(:job) { build(:ci_build, :start_review_app, project: project, ref: ref) }

      context 'and the environment does not exist' do
        it 'creates the environment specified by the job' do
          expect { subject }.to change { Environment.count }.by(1)

          expect(environment).to be_present
          expect(job.persisted_environment.name).to eq("review/#{ref}")
          expect(job.expanded_environment_name).to eq("review/#{ref}")
        end

        context 'and the pipeline is for a merge request' do
          let(:pipeline) do
            build(:ci_pipeline, project: project, ref: ref, stages: [stage], merge_request: merge_request)
          end

          it 'associates the environment with the merge request' do
            expect { subject }.to change { Environment.count }.by(1)

            expect(environment.merge_request).to eq(merge_request)
          end
        end
      end

      context 'when an environment has already been existed' do
        before do
          create(:environment, project: project, name: "review/#{ref}")
        end

        it 'ensures environment existence for the job' do
          expect { subject }.not_to change { Environment.count }

          expect(environment).to be_present
          expect(job.persisted_environment.name).to eq("review/#{ref}")
          expect(job.expanded_environment_name).to eq("review/#{ref}")
        end

        context 'and the pipeline is for a merge request' do
          let(:pipeline) do
            build(:ci_pipeline, project: project, ref: ref, stages: [stage], merge_request: merge_request)
          end

          it 'does not associate the environment with the merge request' do
            expect { subject }.not_to change { Environment.count }

            expect(environment.merge_request).to be_nil
          end
        end
      end

      context 'when an environment name contains an invalid character' do
        let(:pipeline) { build(:ci_pipeline, ref: '!!!', project: project, stages: [stage]) }

        it 'sets the failure status' do
          expect { subject }.not_to change { Environment.count }

          expect(job).to be_failed
          expect(job).to be_environment_creation_failure
          expect(job.persisted_environment).to be_nil
        end
      end
    end

    context 'when a pipeline contains a teardown job' do
      let!(:job) { build(:ci_build, :stop_review_app, project: project, ref: ref) }

      it 'ensures environment existence for the job' do
        expect { subject }.to change { Environment.count }.by(1)

        expect(environment).to be_present
        expect(job.persisted_environment.name).to eq("review/#{ref}")
        expect(job.expanded_environment_name).to eq("review/#{ref}")
      end
    end

    context 'when a pipeline does not contain a deployment job' do
      let!(:job) { build(:ci_build, project: project) }

      it 'does not create any environments' do
        expect { subject }.not_to change { Environment.count }
      end
    end
  end
end
