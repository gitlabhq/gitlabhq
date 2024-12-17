# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RunPipelineScheduleWorker, feature_category: :pipeline_composition do
  it 'has an until_executed deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, namespace: group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, :nightly, project: project) }

    let(:worker) { described_class.new }

    around do |example|
      travel_to(pipeline_schedule.next_run_at + 1.hour) do
        example.run
      end
    end

    context 'when a schedule not found' do
      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect(worker).not_to receive(:run_pipeline_schedule)

        worker.perform(non_existing_record_id, user.id)
      end
    end

    context 'when a schedule project is missing' do
      before do
        project.delete
      end

      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect(worker).not_to receive(:run_pipeline_schedule)

        worker.perform(pipeline_schedule.id, user.id)
      end
    end

    context 'when a user not found' do
      it 'does not call the Service' do
        expect(Ci::CreatePipelineService).not_to receive(:new)
        expect(worker).not_to receive(:run_pipeline_schedule)

        worker.perform(pipeline_schedule.id, non_existing_record_id)
      end
    end

    describe "#run_pipeline_schedule" do
      let(:create_pipeline_service) { instance_double(Ci::CreatePipelineService, execute: service_response) }
      let(:service_response) { instance_double(ServiceResponse, payload: pipeline, error?: false) }
      let(:pipeline) { instance_double(Ci::Pipeline, persisted?: true) }

      context 'when pipeline can be created' do
        before do
          expect(Ci::CreatePipelineService).to receive(:new).with(project, user, ref: pipeline_schedule.ref).and_return(create_pipeline_service)

          expect(create_pipeline_service).to receive(:execute).with(:schedule, ignore_skip_ci: true, save_on_errors: true, schedule: pipeline_schedule).and_return(service_response)
        end

        context "when pipeline is persisted" do
          it "returns the service response" do
            expect(worker.perform(pipeline_schedule.id, user.id)).to eq(service_response)
          end

          it "does not log errors" do
            expect(worker).not_to receive(:log_extra_metadata_on_done)

            expect(worker.perform(pipeline_schedule.id, user.id)).to eq(service_response)
          end

          it "does not change the next_run_at" do
            expect { worker.perform(pipeline_schedule.id, user.id) }.not_to change { pipeline_schedule.reload.next_run_at }
          end

          context 'when scheduling option is given as true' do
            it "returns the service response" do
              expect(worker.perform(pipeline_schedule.id, user.id, scheduling: true)).to eq(service_response)
            end

            it "does not log errors" do
              expect(worker).not_to receive(:log_extra_metadata_on_done)

              expect(worker.perform(pipeline_schedule.id, user.id, scheduling: true)).to eq(service_response)
            end

            it "changes the next_run_at" do
              expect { worker.perform(pipeline_schedule.id, user.id, scheduling: true) }.to change { pipeline_schedule.reload.next_run_at }.by(1.day)
            end
          end
        end
      end

      context 'when schedule is already executed' do
        let(:time_in_future) { 1.hour.since }

        before do
          pipeline_schedule.update_column(:next_run_at, time_in_future)
        end

        it 'does not change the next_run_at' do
          expect { worker.perform(pipeline_schedule.id, user.id) }.to not_change { pipeline_schedule.reload.next_run_at }
        end

        it 'creates a pipeline' do
          expect(Ci::CreatePipelineService).to receive(:new).with(project, user, ref: pipeline_schedule.ref).and_return(create_pipeline_service)
          expect(create_pipeline_service).to receive(:execute).with(:schedule, ignore_skip_ci: true, save_on_errors: true, schedule: pipeline_schedule).and_return(service_response)

          worker.perform(pipeline_schedule.id, user.id)
        end
      end
    end

    context 'when database statement timeout happens' do
      before do
        allow(Ci::CreatePipelineService).to receive(:new) { raise ActiveRecord::StatementInvalid }

        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_for_dev_exception)
          .with(
            ActiveRecord::StatementInvalid,
            issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/41231',
            schedule_id: pipeline_schedule.id
          ).once
      end

      it 'increments Prometheus counter' do
        expect(Gitlab::Metrics)
          .to receive(:counter)
          .with(:pipeline_schedule_creation_failed_total, "Counter of failed attempts of pipeline schedule creation")
          .and_call_original

        worker.perform(pipeline_schedule.id, user.id)
      end

      it 'logging a pipeline error' do
        expect(Gitlab::AppLogger)
          .to receive(:error)
          .with(a_string_matching('ActiveRecord::StatementInvalid'))
          .and_call_original

        worker.perform(pipeline_schedule.id, user.id)
      end
    end
  end
end
