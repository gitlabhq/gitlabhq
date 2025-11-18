# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ShipMergeRequestWorker, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  before_all do
    project.add_maintainer(user)
  end

  describe '#perform' do
    subject(:perform) { described_class.new.perform(user.id, merge_request.id) }

    let(:config) do
      <<~YAML
        workflow:
          rules:
            - if: $CI_MERGE_REQUEST_ID
        rspec:
          script: echo
      YAML
    end

    before do
      stub_ci_pipeline_yaml_file(config)
    end

    context 'when pipeline creation succeeds' do
      it 'creates a pipeline and sets auto-merge with correct SHA' do
        # it executes the auto-merge
        expect_next_instance_of(AutoMergeService) do |service|
          expect(service).to receive(:execute).with(merge_request).and_call_original
        end

        # It triggers GraphQL merge status update
        expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(merge_request).twice

        expect { perform }.to change { ::Ci::Pipeline.count }.by(1)

        expect(perform).to be_success

        # Verify that the merge_request has auto_merge enabled with the correct SHA
        expect(merge_request.reload.auto_merge_enabled?).to be true
        expect(merge_request.merge_params['sha']).to eq(merge_request.diff_head_sha)
        expect(merge_request.head_pipeline_id).to eq(::Ci::Pipeline.last.id)
      end

      context 'when auto-merge fails' do
        before do
          allow_next_instance_of(::AutoMergeService) do |service|
            allow(service).to receive(:execute).and_return(:failed)
          end
        end

        it 'does not set auto-merge' do
          response = perform
          expect(response).to be_error
          expect(response.message).to eq("Failed to enable Auto-Merge on #{merge_request.to_reference}")

          expect(merge_request.reload.auto_merge_enabled?).to be false
        end
      end
    end

    context 'when pipeline creation fails' do
      let(:config) do
        <<~YAML
          rspec:
            script: echo
        YAML
      end

      it 'does not set auto-merge' do
        expect(AutoMergeService).not_to receive(:new)

        # It does not update the head pipeline
        expect(merge_request).not_to receive(:update_head_pipeline)

        expect { perform }.not_to change { ::Ci::Pipeline.count }
        expect(perform).to be_error

        expect(merge_request.reload.auto_merge_enabled?).to be false
      end
    end

    context 'when merge request does not exist' do
      subject(:perform) { described_class.new.perform(user.id, non_existing_record_id) }

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when user does not exist' do
      subject(:perform) { described_class.new.perform(non_existing_record_id, merge_request.id) }

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end
  end

  describe '.allowed?' do
    subject { described_class.allowed?(merge_request: merge_request, current_user: user) }

    let(:create_merge_request_pipeline_service) do
      instance_double(::MergeRequests::CreatePipelineService, allowed?: is_allowed)
    end

    before do
      allow(MergeRequests::CreatePipelineService)
        .to receive(:new)
        .and_return(create_merge_request_pipeline_service)
    end

    context 'when user can create pipeline' do
      let(:is_allowed) { true }

      it { is_expected.to be true }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(ship_mr_quick_action: false)
        end

        it { is_expected.to be false }
      end
    end

    context 'when user cannot create pipeline' do
      let(:is_allowed) { false }

      it { is_expected.to be false }
    end
  end
end
