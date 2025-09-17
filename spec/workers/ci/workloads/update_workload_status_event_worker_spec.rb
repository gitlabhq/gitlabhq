# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Workloads::UpdateWorkloadStatusEventWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be_with_reload(:workload) { create(:ci_workload, project: project, pipeline: pipeline) }
  let(:status) { 'success' }
  let(:data) do
    { pipeline_id: pipeline.id, status: status }
  end

  let(:event) { Ci::PipelineFinishedEvent.new(data: data) }

  it_behaves_like 'subscribes to event'

  describe '#handle_event' do
    subject(:handle_event) { consume_event(subscriber: described_class, event: event) }

    context 'when pipeline cannot be found' do
      let(:data) do
        { pipeline_id: non_existing_record_id, status: status }
      end

      it 'does not change workload state' do
        expect { handle_event }.not_to change { workload.reload.status_name }
      end
    end

    context 'when pipeline is found' do
      context 'when workload cannot be found' do
        let_it_be(:pipeline_without_workload) { create(:ci_pipeline, project: project) }
        let(:data) do
          { pipeline_id: pipeline_without_workload.id, status: status }
        end

        it 'does not change workload state' do
          expect { handle_event }.not_to change { workload.reload.status_name }
        end
      end

      context 'when workload is found' do
        using RSpec::Parameterized::TableSyntax
        where(:pipeline_status, :from_state, :to_state) do
          'success' | :created | :finished
          'failed'  | :created | :failed
        end

        with_them do
          let(:status) { pipeline_status }

          it "moves the workload to #{params[:to_state]}" do
            expect { handle_event }.to change { workload.reload.status_name }.from(from_state).to(to_state)
          end
        end
      end
    end
  end
end
