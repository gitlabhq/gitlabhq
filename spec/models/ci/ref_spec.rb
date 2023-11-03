# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Ref, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  it { is_expected.to belong_to(:project) }

  describe '.ensure_for' do
    let_it_be(:project) { create(:project, :repository) }

    subject { described_class.ensure_for(pipeline) }

    shared_examples_for 'ensures ci_ref' do
      context 'when ci_ref already exists' do
        let(:options) { {} }

        it 'returns an existing ci_ref' do
          expect { subject }.not_to change { described_class.count }

          expect(subject).to eq(described_class.find_by(project_id: project.id, ref_path: expected_ref_path))
        end
      end

      context 'when ci_ref does not exist yet' do
        let(:options) { { ci_ref_presence: false } }

        it 'creates a new ci_ref' do
          expect { subject }.to change { described_class.count }.by(1)

          expect(subject).to eq(described_class.find_by(project_id: project.id, ref_path: expected_ref_path))
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
        create(
          :merge_request,
          target_project: project, target_branch: 'master',
          source_project: project, source_branch: 'feature'
        )
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

  context 'loose foreign key on ci_refs.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_ref, project: parent) }
    end
  end

  describe '#last_successful_ci_source_pipeline' do
    let_it_be(:ci_ref) { create(:ci_ref) }

    let(:ci_source) { Enums::Ci::Pipeline.sources[:push] }
    let(:dangling_source) { Enums::Ci::Pipeline.sources[:parent_pipeline] }

    subject(:result) { ci_ref.last_successful_ci_source_pipeline }

    context 'when there are no successful CI source pipelines' do
      let!(:running_ci_source) { create(:ci_pipeline, :running, ci_ref: ci_ref, source: ci_source) }
      let!(:successful_dangling_source) { create(:ci_pipeline, :success, ci_ref: ci_ref, source: dangling_source) }

      it { is_expected.to be_nil }
    end

    context 'when there are successful CI source pipelines' do
      context 'and the latest pipeline is a successful CI source pipeline' do
        let!(:failed_ci_source) { create(:ci_pipeline, :failed, ci_ref: ci_ref, source: ci_source) }
        let!(:successful_dangling_source) { create(:ci_pipeline, :success, ci_ref: ci_ref, source: dangling_source, child_of: failed_ci_source) }
        let!(:successful_ci_source) { create(:ci_pipeline, :success, ci_ref: ci_ref, source: ci_source) }

        it 'returns the last successful CI source pipeline' do
          expect(result).to eq(successful_ci_source)
        end
      end

      context 'and there is a newer successful dangling source pipeline than the successful CI source pipelines' do
        let!(:successful_ci_source_1) { create(:ci_pipeline, :success, ci_ref: ci_ref, source: ci_source) }
        let!(:successful_ci_source_2) { create(:ci_pipeline, :success, ci_ref: ci_ref, source: ci_source) }
        let!(:failed_ci_source) { create(:ci_pipeline, :failed, ci_ref: ci_ref, source: ci_source) }
        let!(:successful_dangling_source) { create(:ci_pipeline, :success, ci_ref: ci_ref, source: dangling_source, child_of: failed_ci_source) }

        it 'returns the last successful CI source pipeline' do
          expect(result).to eq(successful_ci_source_2)
        end

        context 'and the newer successful dangling source is a child of a successful CI source pipeline' do
          let!(:parent_ci_source) { create(:ci_pipeline, :success, ci_ref: ci_ref, source: ci_source) }
          let!(:successful_child_source) { create(:ci_pipeline, :success, ci_ref: ci_ref, source: dangling_source, child_of: parent_ci_source) }

          it 'returns the parent pipeline instead' do
            expect(result).to eq(parent_ci_source)
          end
        end
      end
    end
  end

  describe '#last_unlockable_ci_source_pipeline' do
    let(:ci_source) { Enums::Ci::Pipeline.sources[:push] }
    let(:dangling_source) { Enums::Ci::Pipeline.sources[:parent_pipeline] }

    let_it_be(:project) { create(:project) }
    let_it_be(:ci_ref) { create(:ci_ref, project: project) }

    subject(:result) { ci_ref.last_unlockable_ci_source_pipeline }

    context 'when there are unlockable pipelines in the ref' do
      context 'and the last CI source pipeline in the ref is unlockable' do
        let!(:unlockable_ci_source_1) { create(:ci_pipeline, :success, project: project, ci_ref: ci_ref, source: ci_source) }
        let!(:unlockable_ci_source_2) { create(:ci_pipeline, :blocked, project: project, ci_ref: ci_ref, source: ci_source) }

        it 'returns the CI source pipeline' do
          expect(result).to eq(unlockable_ci_source_2)
        end

        context 'and it has unlockable child pipelines' do
          let!(:child) { create(:ci_pipeline, :success, project: project, ci_ref: ci_ref, source: dangling_source, child_of: unlockable_ci_source_2) }
          let!(:child_2) { create(:ci_pipeline, :success, project: project, ci_ref: ci_ref, source: dangling_source, child_of: unlockable_ci_source_2) }

          it 'returns the parent CI source pipeline' do
            expect(result).to eq(unlockable_ci_source_2)
          end
        end

        context 'and it has a non-unlockable child pipeline' do
          let!(:child) { create(:ci_pipeline, :running, project: project, ci_ref: ci_ref, source: dangling_source, child_of: unlockable_ci_source_2) }

          it 'returns the parent CI source pipeline' do
            expect(result).to eq(unlockable_ci_source_2)
          end
        end
      end

      context 'and the last CI source pipeline in the ref is not unlockable' do
        let!(:unlockable_ci_source) { create(:ci_pipeline, :skipped, project: project, ci_ref: ci_ref, source: ci_source) }
        let!(:unlockable_dangling_source) { create(:ci_pipeline, :success, project: project, ci_ref: ci_ref, source: dangling_source, child_of: unlockable_ci_source) }
        let!(:non_unlockable_ci_source) { create(:ci_pipeline, :running, project: project, ci_ref: ci_ref, source: ci_source) }
        let!(:non_unlockable_ci_source_2) { create(:ci_pipeline, :running, project: project, ci_ref: ci_ref, source: ci_source) }

        it 'returns the last unlockable CI source pipeline before it' do
          expect(result).to eq(unlockable_ci_source)
        end

        context 'and it has unlockable child pipelines' do
          let!(:child) { create(:ci_pipeline, :success, project: project, ci_ref: ci_ref, source: dangling_source, child_of: non_unlockable_ci_source) }
          let!(:child_2) { create(:ci_pipeline, :success, project: project, ci_ref: ci_ref, source: dangling_source, child_of: non_unlockable_ci_source) }

          it 'returns the last unlockable CI source pipeline before it' do
            expect(result).to eq(unlockable_ci_source)
          end
        end
      end
    end

    context 'when there are no unlockable pipelines in the ref' do
      let!(:non_unlockable_pipeline) { create(:ci_pipeline, :running, project: project, ci_ref: ci_ref, source: ci_source) }
      let!(:pipeline_from_another_ref) { create(:ci_pipeline, :success, source: ci_source) }

      it { is_expected.to be_nil }
    end
  end
end
