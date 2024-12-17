# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeOrchestrationService, feature_category: :code_review_workflow do
  let_it_be(:maintainer) { create(:user) }

  let(:merge_params) { { sha: merge_request.diff_head_sha } }
  let(:user) { maintainer }
  let(:service) { described_class.new(project, user, merge_params) }

  let!(:merge_request) do
    create(
      :merge_request,
      source_project: project, source_branch: 'feature',
      target_project: project, target_branch: 'master'
    )
  end

  shared_context 'fresh repository' do
    let_it_be(:project) { create(:project, :repository) }

    before_all do
      project.add_maintainer(maintainer)
    end
  end

  describe '#execute' do
    subject { service.execute(merge_request) }

    include_context 'fresh repository'

    context 'when merge request is mergeable' do
      context 'when merge request can be merged automatically' do
        before do
          create(:ci_pipeline, :detached_merge_request_pipeline, project: project, merge_request: merge_request)
          merge_request.update_head_pipeline

          stub_licensed_features(merge_request_approvers: true) if Gitlab.ee?
        end

        it 'schedules auto merge' do
          expect_next_instance_of(AutoMergeService, project, user, merge_params) do |service|
            expect(service).to receive(:execute).with(merge_request).and_call_original
          end

          subject

          expect(merge_request).to be_auto_merge_enabled

          expect(merge_request.auto_merge_strategy).to(
            eq(AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS)
          )

          expect(merge_request).not_to be_merged
        end
      end

      context 'when merge request cannot be merged automatically' do
        it 'merges immediately', :sidekiq_inline do
          expect(merge_request)
            .to receive(:merge_async).with(user.id, merge_params)
            .and_call_original

          subject

          merge_request.reset
          expect(merge_request).to be_merged
          expect(merge_request).not_to be_auto_merge_enabled
        end
      end
    end

    context 'when merge request is not mergeable' do
      before do
        allow(merge_request).to receive(:mergeable?) { false }
      end

      it 'does nothing' do
        subject

        expect(merge_request).not_to be_auto_merge_enabled
        expect(merge_request).not_to be_merged
      end
    end
  end

  describe '#can_merge?' do
    subject { service.can_merge?(merge_request) }

    include_context 'fresh repository'

    context 'when merge request is mergeable' do
      it { is_expected.to eq(true) }
    end

    context 'when merge request is not mergeable' do
      before do
        merge_request.update!(merge_status: 'cannot_be_merged')
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#preferred_auto_merge_strategy' do
    subject { service.preferred_auto_merge_strategy(merge_request) }

    include_context 'fresh repository'

    context 'when merge request can be merged automatically' do
      before do
        create(:ci_pipeline, :detached_merge_request_pipeline, project: project, merge_request: merge_request)
        merge_request.update_head_pipeline

        stub_licensed_features(merge_request_approvers: true) if Gitlab.ee?
      end

      it 'fetches preferred auto merge strategy' do
        is_expected.to eq(AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS)
      end
    end

    context 'when merge request cannot be merged automatically' do
      it { is_expected.to be_nil }
    end
  end
end
