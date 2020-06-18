# frozen_string_literal: true

require 'spec_helper'

describe Ci::Ref do
  it { is_expected.to belong_to(:project) }

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

    context 'when feature flag is disabled' do
      let(:pipeline) { create(:ci_pipeline, :success, ci_ref: ci_ref) }

      before do
        stub_feature_flags(ci_pipeline_fixed_notifications: false)
      end

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
