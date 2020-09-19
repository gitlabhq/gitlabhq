# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Ref do
  using RSpec::Parameterized::TableSyntax

  it { is_expected.to belong_to(:project) }

  describe 'state machine transitions' do
    context 'unlock artifacts transition' do
      let(:ci_ref) { create(:ci_ref) }
      let(:unlock_artifacts_worker_spy) { class_spy(::Ci::PipelineSuccessUnlockArtifactsWorker) }

      before do
        stub_const('Ci::PipelineSuccessUnlockArtifactsWorker', unlock_artifacts_worker_spy)
      end

      where(:initial_state, :action, :count) do
        :unknown | :succeed! | 1
        :unknown | :do_fail! | 0
        :success | :succeed! | 1
        :success | :do_fail! | 0
        :failed | :succeed! | 1
        :failed | :do_fail! | 0
        :fixed | :succeed! | 1
        :fixed | :do_fail! | 0
        :broken | :succeed! | 1
        :broken | :do_fail! | 0
        :still_failing | :succeed | 1
        :still_failing | :do_fail | 0
      end

      with_them do
        context "when transitioning states" do
          before do
            status_value = Ci::Ref.state_machines[:status].states[initial_state].value
            ci_ref.update!(status: status_value)
          end

          it 'calls unlock artifacts service' do
            ci_ref.send(action)

            expect(unlock_artifacts_worker_spy).to have_received(:perform_async).exactly(count).times
          end
        end
      end
    end
  end

  describe '.ensure_for' do
    let_it_be(:project) { create(:project, :repository) }

    subject { described_class.ensure_for(pipeline) }

    shared_examples_for 'ensures ci_ref' do
      context 'when ci_ref already exists' do
        let(:options) { {} }

        it 'returns an existing ci_ref' do
          expect { subject }.not_to change { described_class.count }

          expect(subject).to eq(Ci::Ref.find_by(project_id: project.id, ref_path: expected_ref_path))
        end
      end

      context 'when ci_ref does not exist yet' do
        let(:options) { { ci_ref_presence: false } }

        it 'creates a new ci_ref' do
          expect { subject }.to change { described_class.count }.by(1)

          expect(subject).to eq(Ci::Ref.find_by(project_id: project.id, ref_path: expected_ref_path))
        end
      end
    end

    context 'when pipeline is a branch pipeline' do
      let!(:pipeline) { create(:ci_pipeline, ref: 'master', project: project, **options) }
      let(:expected_ref_path) { 'refs/heads/master' }

      it_behaves_like 'ensures ci_ref'
    end

    context 'when pipeline is a tag pipeline' do
      let!(:pipeline) { create(:ci_pipeline, ref: 'v1.1.0', tag: true, project: project, **options) }
      let(:expected_ref_path) { 'refs/tags/v1.1.0' }

      it_behaves_like 'ensures ci_ref'
    end

    context 'when pipeline is a detached merge request pipeline' do
      let(:merge_request) do
        create(:merge_request, target_project: project, target_branch: 'master',
                               source_project: project, source_branch: 'feature')
      end

      let!(:pipeline) do
        create(:ci_pipeline, :detached_merge_request_pipeline, merge_request: merge_request, project: project, **options)
      end

      let(:expected_ref_path) { 'refs/heads/feature' }

      it_behaves_like 'ensures ci_ref'
    end
  end

  describe '#last_finished_pipeline_id' do
    let(:pipeline_status) { :running }
    let(:pipeline_source) { Enums::Ci::Pipeline.sources[:push] }
    let(:pipeline) { create(:ci_pipeline, pipeline_status, source: pipeline_source) }
    let(:ci_ref) { pipeline.ci_ref }

    context 'when there are no finished pipelines' do
      it 'returns nil' do
        expect(ci_ref.last_finished_pipeline_id).to be_nil
      end
    end

    context 'when there are finished pipelines' do
      let(:pipeline_status) { :success }

      it 'returns the pipeline id' do
        expect(ci_ref.last_finished_pipeline_id).to eq(pipeline.id)
      end

      context 'when the pipeline a dangling pipeline' do
        let(:pipeline_source) { Enums::Ci::Pipeline.sources[:ondemand_dast_scan] }

        it 'returns nil' do
          expect(ci_ref.last_finished_pipeline_id).to be_nil
        end
      end
    end
  end

  describe '#update_status_by!' do
    subject { ci_ref.update_status_by!(pipeline) }

    let!(:ci_ref) { create(:ci_ref) }

    shared_examples_for 'no-op' do
      it 'does nothing and returns nil' do
        expect { subject }.not_to change { ci_ref.status_name }

        is_expected.to be_nil
      end
    end

    context 'when pipeline status is success or failed' do
      using RSpec::Parameterized::TableSyntax

      where(:pipeline_status, :current_ref_status, :expected_ref_status) do
        :success   | :unknown       | :success
        :success   | :success       | :success
        :success   | :failed        | :fixed
        :success   | :fixed         | :success
        :success   | :broken        | :fixed
        :success   | :still_failing | :fixed
        :failed    | :unknown       | :failed
        :failed    | :success       | :broken
        :failed    | :failed        | :still_failing
        :failed    | :fixed         | :broken
        :failed    | :broken        | :still_failing
        :failed    | :still_failing | :still_failing
      end

      with_them do
        let(:ci_ref) { create(:ci_ref, status: described_class.state_machines[:status].states[current_ref_status].value) }
        let(:pipeline) { create(:ci_pipeline, status: pipeline_status, ci_ref: ci_ref) }

        it 'transitions the status via state machine' do
          expect(subject).to eq(expected_ref_status)
          expect(ci_ref.status_name).to eq(expected_ref_status)
        end
      end
    end

    context 'when pipeline status is success' do
      let(:pipeline) { create(:ci_pipeline, :success, ci_ref: ci_ref) }

      it 'updates the status' do
        expect { subject }.to change { ci_ref.status_name }.from(:unknown).to(:success)

        is_expected.to eq(:success)
      end
    end

    context 'when pipeline status is canceled' do
      let(:pipeline) { create(:ci_pipeline, status: :canceled, ci_ref: ci_ref) }

      it { is_expected.to eq(:unknown) }
    end

    context 'when pipeline status is skipped' do
      let(:pipeline) { create(:ci_pipeline, status: :skipped, ci_ref: ci_ref) }

      it_behaves_like 'no-op'
    end

    context 'when pipeline status is not complete' do
      let(:pipeline) { create(:ci_pipeline, :running, ci_ref: ci_ref) }

      it_behaves_like 'no-op'
    end

    context 'when pipeline is not the latest pipeline' do
      let!(:pipeline) { create(:ci_pipeline, :success, ci_ref: ci_ref) }
      let!(:latest_pipeline) { create(:ci_pipeline, :success, ci_ref: ci_ref) }

      it_behaves_like 'no-op'
    end

    context 'when pipeline does not belong to the ci_ref' do
      let(:pipeline) { create(:ci_pipeline, :success, ci_ref: create(:ci_ref)) }

      it_behaves_like 'no-op'
    end
  end
end
