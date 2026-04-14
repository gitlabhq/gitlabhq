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

    context 'when pipeline is being created' do
      before do
        allow(mr_merge_if_green_enabled).to receive(:pipeline_creating?).and_return(true)
      end

      it { is_expected.to eq true }
    end

    context 'when merge request is mergeable and pipeline is not in progress' do
      before do
        allow(mr_merge_if_green_enabled).to receive(:mergeable?).and_return(true)
        allow(mr_merge_if_green_enabled).to receive(:diff_head_pipeline_considered_in_progress?).and_return(false)
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
    let(:merge_request) do
      create(:merge_request,
        merge_when_pipeline_succeeds: true,
        merge_user: user,
        auto_merge_enabled: true,
        auto_merge_strategy: AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS,
        source_branch: 'feature', target_branch: 'master',
        source_project: project, target_project: project)
    end

    subject(:process) { service.process(merge_request) }

    context 'with CI pipeline in various states' do
      before do
        project.update!(only_allow_merge_if_pipeline_succeeds: true)

        create(:ci_pipeline,
          status: pipeline_status,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha,
          project: project,
          head_pipeline_of: merge_request)
        merge_request.update_head_pipeline
        project.update!(allow_merge_on_skipped_pipeline: allow_skipped)
      end

      where(:pipeline_status, :allow_skipped, :expected_merge) do
        :success | false | true
        :failed  | false | false
        :running | false | false
        :skipped | true  | true
        :skipped | false | false
      end

      with_them do
        it 'merges or blocks based on pipeline state and project settings' do
          if expected_merge
            expect(merge_request).to receive(:merge_async)
          else
            expect(merge_request).not_to receive(:merge_async)
          end

          process
        end
      end
    end

    context 'when the head pipeline is nil and CI is enabled' do
      before do
        project.update!(only_allow_merge_if_pipeline_succeeds: true)
        create(:ci_pipeline, project: project)
      end

      it 'does not merge' do
        expect(merge_request).not_to receive(:merge_async)

        process
      end
    end

    context 'when the merge request is not mergeable' do
      before do
        merge_request.update!(title: merge_request.draft_title)
      end

      it 'does not call the merge worker' do
        expect(merge_request).not_to receive(:merge_async)

        process
      end
    end

    context 'when mwcp_skip_ci_guard feature flag is disabled' do
      before do
        stub_feature_flags(mwcp_skip_ci_guard: false)
      end

      context 'when CI is enabled and pipeline has not succeeded' do
        before do
          project.update!(only_allow_merge_if_pipeline_succeeds: true)

          create(:ci_pipeline, :skipped,
            ref: merge_request.source_branch,
            sha: merge_request.diff_head_sha,
            project: project,
            head_pipeline_of: merge_request)
          merge_request.update_head_pipeline

          project.update!(allow_merge_on_skipped_pipeline: true)
        end

        it 'blocks merge due to the early CI guard even when skipped pipelines are allowed' do
          expect(merge_request).not_to receive(:merge_async)

          process
        end
      end

      context 'when CI is enabled and pipeline has succeeded' do
        before do
          project.update!(only_allow_merge_if_pipeline_succeeds: true)

          create(:ci_pipeline, :success,
            ref: merge_request.source_branch,
            sha: merge_request.diff_head_sha,
            project: project,
            head_pipeline_of: merge_request)
          merge_request.update_head_pipeline
        end

        it 'calls the merge worker' do
          expect(merge_request).to receive(:merge_async)

          process
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
