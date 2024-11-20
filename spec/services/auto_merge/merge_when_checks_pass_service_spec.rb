# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMerge::MergeWhenChecksPassService, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  include_context 'for auto_merge strategy context'

  let(:approval_rule) do
    create(:approval_merge_request_rule, merge_request: mr_merge_if_green_enabled,
      approvals_required: approvals_required)
  end

  describe '#available_for?' do
    subject { service.available_for?(mr_merge_if_green_enabled) }

    context 'when immediately mergeable' do
      context 'when a non active pipeline' do
        before do
          create(:ci_pipeline, :success,
            ref: mr_merge_if_green_enabled.source_branch,
            sha: mr_merge_if_green_enabled.diff_head_sha,
            project: mr_merge_if_green_enabled.source_project)
          mr_merge_if_green_enabled.update_head_pipeline
        end

        it { is_expected.to eq false }
      end

      context 'when an active pipeline' do
        before do
          create(:ci_pipeline, :running,
            ref: mr_merge_if_green_enabled.source_branch,
            sha: mr_merge_if_green_enabled.diff_head_sha,
            project: mr_merge_if_green_enabled.source_project)
          mr_merge_if_green_enabled.update_head_pipeline
        end

        it { is_expected.to eq true }
      end
    end

    context 'when draft status' do
      before do
        mr_merge_if_green_enabled.update!(title: 'Draft: check')
      end

      it { is_expected.to eq true }
    end

    context 'when discussions open' do
      before do
        allow(mr_merge_if_green_enabled).to receive(:mergeable_discussions_state?).and_return(false)
        allow(mr_merge_if_green_enabled)
          .to receive(:only_allow_merge_if_all_discussions_are_resolved?).and_return(true)
      end

      it { is_expected.to eq true }
    end

    context 'when pipline is active' do
      before do
        create(:ci_pipeline, :running,
          ref: mr_merge_if_green_enabled.source_branch,
          sha: mr_merge_if_green_enabled.diff_head_sha,
          project: mr_merge_if_green_enabled.source_project)

        mr_merge_if_green_enabled.update_head_pipeline
      end

      it { is_expected.to eq true }
    end

    context 'when the user does not have permission to merge' do
      before do
        allow(mr_merge_if_green_enabled).to receive(:can_be_merged_by?).and_return(false)
      end

      it { is_expected.to eq false }
    end
  end

  describe "#execute" do
    let(:merge_request) do
      create(:merge_request, target_project: project, source_project: project,
        source_branch: 'feature', target_branch: 'master')
    end

    context 'when the MR is available for auto merge' do
      let(:auto_merge_strategy) { ::AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS }

      before do
        merge_request.update!(merge_params: { sha: pipeline.sha }, title: 'Draft: check')
      end

      context 'when first time enabling' do
        before do
          allow(merge_request)
            .to receive_messages(head_pipeline: pipeline, diff_head_pipeline: pipeline)
          allow(MailScheduler::NotificationServiceWorker).to receive(:perform_async)

          service.execute(merge_request)
        end

        it 'sets the params, merge_user, and flag' do
          expect(merge_request).to be_valid
          expect(merge_request.merge_when_pipeline_succeeds).to be_truthy
          expect(merge_request.merge_params).to include 'commit_message' => 'Awesome message'
          expect(merge_request.merge_user).to be user
          expect(merge_request.auto_merge_strategy).to eq auto_merge_strategy
        end

        it 'schedules a notification' do
          expect(MailScheduler::NotificationServiceWorker).to have_received(:perform_async).with(
            'merge_when_pipeline_succeeds', merge_request, user).once
        end

        it 'creates a system note' do
          pipeline = build(:ci_pipeline)
          allow(merge_request).to receive(:diff_head_pipeline) { pipeline }

          note = merge_request.notes.last
          expect(note.note).to match "enabled an automatic merge when all merge checks for #{pipeline.sha} pass"
        end
      end

      context 'when mergeable' do
        it 'updates the merge params' do
          expect(SystemNoteService).not_to receive(:merge_when_pipeline_succeeds)
          expect(MailScheduler::NotificationServiceWorker).not_to receive(:perform_async).with(
            'merge_when_pipeline_succeeds', any_args)

          service.execute(mr_merge_if_green_enabled)
        end
      end
    end
  end

  describe "#process" do
    context 'when the merge request does not have a ci config' do
      before do
        allow(mr_merge_if_green_enabled).to receive(:has_ci_enabled?).and_return(false)
      end

      context 'when the merge request is mergable' do
        it 'calls the merge worker' do
          expect(mr_merge_if_green_enabled)
            .to receive(:merge_async)
            .with(mr_merge_if_green_enabled.merge_user_id, mr_merge_if_green_enabled.merge_params)

          service.process(mr_merge_if_green_enabled)
        end
      end

      context 'when the merge request is not mergeable' do
        it 'does not call the merge worker' do
          expect(mr_merge_if_green_enabled).to receive(:mergeable?).and_return(false)
          expect(mr_merge_if_green_enabled).not_to receive(:merge_async)

          service.process(mr_merge_if_green_enabled)
        end
      end
    end

    context 'when the merge request has a ci config' do
      before do
        allow(mr_merge_if_green_enabled).to receive(:has_ci_enabled?).and_return(true)
      end

      context 'when the pipeline has not succeeded' do
        before do
          allow(mr_merge_if_green_enabled).to receive(:diff_head_pipeline_success?).and_return(false)
        end

        it 'does not call the merge worker' do
          expect(mr_merge_if_green_enabled).not_to receive(:merge_async)

          service.process(mr_merge_if_green_enabled)
        end
      end

      context 'when the pipeline has succeeded' do
        before do
          allow(mr_merge_if_green_enabled).to receive(:diff_head_pipeline_success?).and_return(true)
          allow_next_instance_of(MergeRequests::Mergeability::CheckCiStatusService) do |check|
            allow(check).to receive(:mergeable_ci_state?).and_return(true)
          end
        end

        context 'when the merge request is mergable' do
          it 'calls the merge worker' do
            expect(mr_merge_if_green_enabled)
              .to receive(:merge_async)
              .with(mr_merge_if_green_enabled.merge_user_id, mr_merge_if_green_enabled.merge_params)

            service.process(mr_merge_if_green_enabled)
          end
        end

        context 'when the merge request is not mergeable' do
          it 'does not call the merge worker' do
            expect(mr_merge_if_green_enabled).to receive(:mergeable?).and_return(false)
            expect(mr_merge_if_green_enabled).not_to receive(:merge_async)

            service.process(mr_merge_if_green_enabled)
          end
        end
      end
    end
  end

  describe '#cancel' do
    it_behaves_like 'auto_merge service #cancel'
  end

  describe '#abort' do
    it_behaves_like 'auto_merge service #abort'
  end
end
