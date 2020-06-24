# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineScheduleWorker do
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

    pipeline_schedule.update_column(:next_run_at, 1.day.ago)
  end

  context 'when the schedule is runnable by the user' do
    before do
      project.add_maintainer(user)
    end

    context 'when there is a scheduled pipeline within next_run_at' do
      shared_examples 'successful scheduling' do
        it 'creates a new pipeline', :sidekiq_might_not_need_inline do
          expect { subject }.to change { project.ci_pipelines.count }.by(1)
          expect(Ci::Pipeline.last).to be_schedule

          pipeline_schedule.reload
          expect(pipeline_schedule.next_run_at).to be > Time.current
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
end
