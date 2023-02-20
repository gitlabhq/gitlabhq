# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineScheduleWorker, :sidekiq_inline, feature_category: :continuous_integration do
  include ExclusiveLeaseHelpers

  subject { described_class.new.perform }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let!(:pipeline_schedule) do
    create(:ci_pipeline_schedule, :nightly, project: project, owner: user)
  end

  before do
    stub_application_setting(auto_devops_enabled: false)
    stub_ci_pipeline_to_return_yaml_file
  end

  around do |example|
    travel_to(pipeline_schedule.next_run_at + 1.hour) do
      example.run
    end
  end

  context 'when the schedule is runnable by the user' do
    before do
      project.add_maintainer(user)
    end

    context 'when there is a scheduled pipeline within next_run_at' do
      shared_examples 'successful scheduling' do
        it 'creates a new pipeline' do
          expect { subject }.to change { project.ci_pipelines.count }.by(1)
          last_pipeline = project.ci_pipelines.last

          expect(last_pipeline).to be_schedule
          expect(last_pipeline.pipeline_schedule).to eq(pipeline_schedule)
        end

        it 'updates next_run_at' do
          expect { subject }.to change { pipeline_schedule.reload.next_run_at }.by(1.day)
        end

        it 'does not change active status' do
          expect { subject }.not_to change { pipeline_schedule.reload.active? }.from(true)
        end
      end

      it_behaves_like 'successful scheduling'

      context 'when the latest commit contains [ci skip]' do
        before do
          allow_any_instance_of(Ci::Pipeline)
            .to receive(:git_commit_message)
            .and_return('some commit [ci skip]')
        end

        it_behaves_like 'successful scheduling'
      end
    end

    context 'when the schedule is deactivated' do
      before do
        pipeline_schedule.deactivate!
      end

      it 'does not creates a new pipeline' do
        expect { subject }.not_to change { project.ci_pipelines.count }
      end
    end

    context 'when gitlab-ci.yml is corrupted' do
      before do
        stub_ci_pipeline_yaml_file(YAML.dump(rspec: { variables: 'rspec' } ))
      end

      it 'does not creates a new pipeline' do
        expect { subject }.not_to change { project.ci_pipelines.count }
      end
    end
  end

  context 'when the schedule is not runnable by the user' do
    it 'does not deactivate the schedule' do
      subject

      expect(pipeline_schedule.reload.active).to be_truthy
    end

    it 'does not create a pipeline' do
      expect { subject }.not_to change { project.ci_pipelines.count }
    end

    it 'does not raise an exception' do
      expect { subject }.not_to raise_error
    end
  end

  context 'when .gitlab-ci.yml is missing in the project' do
    before do
      stub_ci_pipeline_yaml_file(nil)
      project.add_maintainer(user)
    end

    it 'does not create a pipeline' do
      expect { subject }.not_to change { project.ci_pipelines.count }
    end

    it 'does not raise an exception' do
      expect { subject }.not_to raise_error
    end
  end

  context 'when the project is missing' do
    before do
      project.delete
    end

    it 'does not raise an exception' do
      expect { subject }.not_to raise_error
    end
  end

  context 'when max retry attempts reach' do
    let!(:lease) { stub_exclusive_lease_taken(described_class.name.underscore) }

    it 'does not raise error' do
      expect(lease).to receive(:try_obtain).exactly(described_class::LOCK_RETRY + 1).times
      expect { subject }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
    end
  end
end
