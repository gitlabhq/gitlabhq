# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::EnsureEnvironments do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:stage) { build(:ci_stage, project: project, statuses: [job]) }
  let(:pipeline) { build(:ci_pipeline, project: project, stages: [stage]) }

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
      let!(:job) { build(:ci_build, :start_review_app, project: project) }

      it 'ensures environment existence for the job' do
        expect { subject }.to change { Environment.count }.by(1)

        expect(project.environments.find_by_name('review/master')).to be_present
        expect(job.persisted_environment.name).to eq('review/master')
        expect(job.metadata.expanded_environment_name).to eq('review/master')
      end

      context 'when an environment has already been existed' do
        before do
          create(:environment, project: project, name: 'review/master')
        end

        it 'ensures environment existence for the job' do
          expect { subject }.not_to change { Environment.count }

          expect(project.environments.find_by_name('review/master')).to be_present
          expect(job.persisted_environment.name).to eq('review/master')
          expect(job.metadata.expanded_environment_name).to eq('review/master')
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
      let!(:job) { build(:ci_build, :stop_review_app, project: project) }

      it 'ensures environment existence for the job' do
        expect { subject }.to change { Environment.count }.by(1)

        expect(project.environments.find_by_name('review/master')).to be_present
        expect(job.persisted_environment.name).to eq('review/master')
        expect(job.metadata.expanded_environment_name).to eq('review/master')
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
