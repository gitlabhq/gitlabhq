# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMergeProcessWorker, feature_category: :continuous_delivery do
  let(:merge_request) { create(:merge_request) }

  describe '#perform' do
    subject { described_class.new.perform(args) }

    let(:args) { { 'merge_request_id' => merge_request.id } }

    context 'when merge request is found' do
      it 'executes AutoMergeService' do
        expect_next_instance_of(AutoMergeService) do |auto_merge|
          expect(auto_merge).to receive(:process).with(merge_request)
        end

        subject
      end
    end

    context 'when merge request is not found' do
      let(:args) { { 'merge_request_id' => -1 } }

      it 'does not execute AutoMergeService' do
        expect(AutoMergeService).not_to receive(:new)

        subject
      end
    end

    context 'when a pipeline is passed with auto mergeable MRs', :aggregate_failures do
      let(:merge_service) { instance_double(AutoMergeService, process: true) }
      let(:mwps_merge_request) { create(:merge_request, :with_head_pipeline, :merge_when_pipeline_succeeds) }
      let(:mwcp_merge_request) { create(:merge_request, :with_head_pipeline, :merge_when_checks_pass) }

      let(:args) do
        {
          'merge_request_id' => merge_request.id,
          'pipeline_id' => [mwps_merge_request.head_pipeline.id, mwcp_merge_request.head_pipeline.id]
        }
      end

      it 'initializes and executes AutoMergeService for the passed MR and those attached to the passed pipeline' do
        expect(AutoMergeService).to receive(:new).exactly(3).times.and_return(merge_service)

        expect(merge_service).to receive(:process).with(merge_request)
        expect(merge_service).to receive(:process).with(mwps_merge_request)
        expect(merge_service).to receive(:process).with(mwcp_merge_request)

        subject
      end
    end

    context 'when pipeline is not found' do
      let(:args) { { 'pipeline_id' => -1 } }

      it 'does not execute AutoMergeService' do
        expect(AutoMergeService).not_to receive(:new)

        subject
      end
    end

    context 'when merge request id is nil' do
      let(:args) { { 'merge_request_id' => nil } }

      it 'does not execute AutoMergeService' do
        expect(AutoMergeService).not_to receive(:new)

        subject
      end
    end

    # Integer args are deprecated as of 17.5. IDs should be passed
    # as a hash with  merge_request_id and pipeline_id keys.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/497247
    context 'with integer args' do
      let(:args) { merge_request.id }

      context 'when merge request is found' do
        it 'executes AutoMergeService' do
          expect_next_instance_of(AutoMergeService) do |auto_merge|
            expect(auto_merge).to receive(:process)
          end

          subject
        end
      end

      context 'when merge request is not found' do
        let(:args) { -1 }

        it 'does not execute AutoMergeService' do
          expect(AutoMergeService).not_to receive(:new)

          subject
        end
      end

      context 'when merge request id is nil' do
        let(:args) { nil }

        it 'does not execute AutoMergeService' do
          expect(AutoMergeService).not_to receive(:new)

          subject
        end
      end
    end
  end
end
