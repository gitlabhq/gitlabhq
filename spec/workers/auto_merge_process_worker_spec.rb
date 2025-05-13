# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMergeProcessWorker, feature_category: :continuous_delivery do
  let(:merge_request) { create(:merge_request, :unique_branches) }

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

    context 'when a project id is passed' do
      let_it_be(:project) { create(:project) }
      let(:project_id) { project.id }
      let(:merge_service) { instance_double(AutoMergeService, process: true) }
      let!(:mwcp_merge_request_1) do
        create(:merge_request, :unique_branches, :with_head_pipeline, :merge_when_checks_pass, target_project: project,
          source_project: project)
      end

      let!(:mwcp_merge_request_2) do
        create(:merge_request, :unique_branches, :with_head_pipeline, :merge_when_checks_pass, target_project: project,
          source_project: project)
      end

      let!(:normal_merge_request_2) do
        create(:merge_request, :unique_branches, :with_head_pipeline, target_project: project, source_project: project)
      end

      let(:args) do
        {
          'project_id' => project_id,
          'merge_request_id' => merge_request.id
        }
      end

      it 'executes the auto merge service for only auto merge MRs' do
        expect(AutoMergeService).to receive(:new).exactly(3).times.and_return(merge_service)

        expect(merge_service).to receive(:process).with(merge_request)
        expect(merge_service).to receive(:process).with(mwcp_merge_request_1)
        expect(merge_service).to receive(:process).with(mwcp_merge_request_2)

        subject
      end

      context 'when the project id is not valid' do
        let(:project_id) { -1 }

        it 'executes the auto merge service for only the merge request' do
          expect(AutoMergeService).to receive(:new).once.and_return(merge_service)

          expect(merge_service).to receive(:process).with(merge_request)

          subject
        end
      end

      context 'when the merge_request_title_regex feature flag is off' do
        before do
          stub_feature_flags(merge_request_title_regex: false)
        end

        it 'executes the auto merge service for only the merge request' do
          expect(AutoMergeService).to receive(:new).once.and_return(merge_service)

          expect(merge_service).to receive(:process).with(merge_request)

          subject
        end
      end

      context 'when there are more merge requests than the limit' do
        let(:args) do
          {
            'project_id' => project_id
          }
        end

        before do
          stub_const("AutoMergeProcessWorker::PROJECT_MR_LIMIT", 1)
        end

        it 'executes the auto merge service for limited auto merge MRs' do
          expect(AutoMergeService).to receive(:new).once.and_return(merge_service)

          expect(merge_service).to receive(:process).with(mwcp_merge_request_1)

          subject
        end
      end
    end

    context 'when a pipeline is passed with auto mergeable MRs', :aggregate_failures do
      let(:merge_service) { instance_double(AutoMergeService, process: true) }
      let(:mwcp_merge_request) { create(:merge_request, :with_head_pipeline, :merge_when_checks_pass) }

      let(:args) do
        {
          'merge_request_id' => merge_request.id,
          'pipeline_id' => [mwcp_merge_request.head_pipeline.id]
        }
      end

      it 'initializes and executes AutoMergeService for the passed MR and those attached to the passed pipeline' do
        expect(AutoMergeService).to receive(:new).twice.and_return(merge_service)

        expect(merge_service).to receive(:process).with(merge_request)
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
