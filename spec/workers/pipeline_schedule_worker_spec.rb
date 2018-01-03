require 'spec_helper'

describe PipelineScheduleWorker do
  subject { described_class.new.perform }

  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let!(:pipeline_schedule) do
    create(:ci_pipeline_schedule, :nightly, project: project, owner: user)
  end

  before do
    stub_ci_pipeline_to_return_yaml_file

    pipeline_schedule.update_column(:next_run_at, 1.day.ago)
  end

  context 'when the schedule is runnable by the user' do
    before do
      project.add_master(user)
    end

    context 'when there is a scheduled pipeline within next_run_at' do
      shared_examples 'successful scheduling' do
        it 'creates a new pipeline' do
          expect { subject }.to change { project.pipelines.count }.by(1)
          expect(Ci::Pipeline.last).to be_schedule

          pipeline_schedule.reload
          expect(pipeline_schedule.next_run_at).to be > Time.now
          expect(pipeline_schedule).to eq(project.pipelines.last.pipeline_schedule)
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
        expect { subject }.not_to change { project.pipelines.count }
      end
    end
  end

  context 'when the schedule is not runnable by the user' do
    it 'deactivates the schedule' do
      subject

      expect(pipeline_schedule.reload.active).to be_falsy
    end

    it 'does not schedule a pipeline' do
      expect { subject }.not_to change { project.pipelines.count }
    end
  end
end
