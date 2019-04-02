# frozen_string_literal: true

require 'spec_helper'

describe PipelineScheduleWorker do
  subject { described_class.new.perform }

  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let!(:pipeline_schedule) do
    create(:ci_pipeline_schedule, :nightly, project: project, owner: user)
  end

  before do
    stub_application_setting(auto_devops_enabled: false)
    stub_ci_pipeline_to_return_yaml_file

    pipeline_schedule.update_column(:next_run_at, 1.day.ago)
  end

  context 'when the schedule is runnable by the user' do
    before do
      project.add_maintainer(user)
    end

    context 'when there is a scheduled pipeline within next_run_at' do
      shared_examples 'successful scheduling' do
        it 'creates a new pipeline' do
          expect { subject }.to change { project.ci_pipelines.count }.by(1)
          expect(Ci::Pipeline.last).to be_schedule

          pipeline_schedule.reload
          expect(pipeline_schedule.next_run_at).to be > Time.now
          expect(pipeline_schedule).to eq(project.ci_pipelines.last.pipeline_schedule)
          expect(pipeline_schedule).to be_active
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

      it 'creates a failed pipeline with the reason' do
        expect { subject }.to change { project.ci_pipelines.count }.by(1)
        expect(Ci::Pipeline.last).to be_config_error
        expect(Ci::Pipeline.last.yaml_errors).not_to be_nil
      end
    end
  end

  context 'when the schedule is not runnable by the user' do
    before do
      expect(Gitlab::Sentry)
        .to receive(:track_exception)
        .with(Ci::CreatePipelineService::CreateError,
              issue_url: 'https://gitlab.com/gitlab-org/gitlab-ce/issues/41231',
              extra: { schedule_id: pipeline_schedule.id } ).once
    end

    it 'does not deactivate the schedule' do
      subject

      expect(pipeline_schedule.reload.active).to be_truthy
    end

    it 'increments Prometheus counter' do
      expect(Gitlab::Metrics)
        .to receive(:counter)
        .with(:pipeline_schedule_creation_failed_total, "Counter of failed attempts of pipeline schedule creation")
        .and_call_original

      subject
    end

    it 'logging a pipeline error' do
      expect(Rails.logger)
        .to receive(:error)
        .with(a_string_matching("Insufficient permissions to create a new pipeline"))
        .and_call_original

      subject
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

      expect(Gitlab::Sentry)
        .to receive(:track_exception)
        .with(Ci::CreatePipelineService::CreateError,
              issue_url: 'https://gitlab.com/gitlab-org/gitlab-ce/issues/41231',
              extra: { schedule_id: pipeline_schedule.id } ).once
    end

    it 'logging a pipeline error' do
      expect(Rails.logger)
        .to receive(:error)
        .with(a_string_matching("Missing .gitlab-ci.yml file"))
        .and_call_original

      subject
    end

    it 'does not create a pipeline' do
      expect { subject }.not_to change { project.ci_pipelines.count }
    end

    it 'does not raise an exception' do
      expect { subject }.not_to raise_error
    end
  end
end
