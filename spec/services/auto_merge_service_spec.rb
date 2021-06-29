# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMergeService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  before_all do
    project.add_maintainer(user)
  end

  describe '.all_strategies_ordered_by_preference' do
    subject { described_class.all_strategies_ordered_by_preference }

    it 'returns all strategies in preference order' do
      if Gitlab.ee?
        is_expected.to eq(
          [AutoMergeService::STRATEGY_MERGE_TRAIN,
           AutoMergeService::STRATEGY_ADD_TO_MERGE_TRAIN_WHEN_PIPELINE_SUCCEEDS,
           AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS])
      else
        is_expected.to eq([AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS])
      end
    end
  end

  describe '#available_strategies' do
    subject { service.available_strategies(merge_request) }

    let(:merge_request) do
      create(:merge_request, source_project: project)
    end

    let(:pipeline_status) { :running }

    before do
      create(:ci_pipeline, pipeline_status, ref: merge_request.source_branch,
                                            sha: merge_request.diff_head_sha,
                                            project: merge_request.source_project)

      merge_request.update_head_pipeline
    end

    it 'returns available strategies' do
      is_expected.to include('merge_when_pipeline_succeeds')
    end

    context 'when the head piipeline succeeded' do
      let(:pipeline_status) { :success }

      it 'returns available strategies' do
        is_expected.to be_empty
      end
    end
  end

  describe '#preferred_strategy' do
    subject { service.preferred_strategy(merge_request) }

    let(:merge_request) do
      create(:merge_request, source_project: project)
    end

    let(:pipeline_status) { :running }

    before do
      create(:ci_pipeline, pipeline_status, ref: merge_request.source_branch,
                                            sha: merge_request.diff_head_sha,
                                            project: merge_request.source_project)

      merge_request.update_head_pipeline
    end

    it 'returns preferred strategy' do
      is_expected.to eq('merge_when_pipeline_succeeds')
    end

    context 'when the head piipeline succeeded' do
      let(:pipeline_status) { :success }

      it 'returns available strategies' do
        is_expected.to be_nil
      end
    end
  end

  describe '.get_service_class' do
    subject { described_class.get_service_class(strategy) }

    let(:strategy) { AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS }

    it 'returns service instance' do
      is_expected.to eq(AutoMerge::MergeWhenPipelineSucceedsService)
    end

    context 'when strategy is not present' do
      let(:strategy) { }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#execute' do
    subject { service.execute(merge_request, strategy) }

    let(:merge_request) do
      create(:merge_request, source_project: project)
    end

    let(:pipeline_status) { :running }
    let(:strategy) { AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS }

    before do
      create(:ci_pipeline, pipeline_status, ref: merge_request.source_branch,
                                            sha: merge_request.diff_head_sha,
                                            project: merge_request.source_project)

      merge_request.update_head_pipeline
    end

    it 'delegates to a relevant service instance' do
      expect_next_instance_of(AutoMerge::MergeWhenPipelineSucceedsService) do |service|
        expect(service).to receive(:execute).with(merge_request)
      end

      subject
    end

    context 'when the head piipeline succeeded' do
      let(:pipeline_status) { :success }

      it 'returns failed' do
        is_expected.to eq(:failed)
      end
    end

    context 'when strategy is not specified' do
      let(:strategy) { }

      it 'chooses the most preferred strategy' do
        is_expected.to eq(:merge_when_pipeline_succeeds)
      end
    end
  end

  describe '#update' do
    subject { service.update(merge_request) } # rubocop:disable Rails/SaveBang

    context 'when auto merge is enabled' do
      let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }

      it 'delegates to a relevant service instance' do
        expect_next_instance_of(AutoMerge::MergeWhenPipelineSucceedsService) do |service|
          expect(service).to receive(:update).with(merge_request)
        end

        subject
      end
    end

    context 'when auto merge is not enabled' do
      let(:merge_request) { create(:merge_request) }

      it 'returns failed' do
        is_expected.to eq(:failed)
      end
    end
  end

  describe '#process' do
    subject { service.process(merge_request) }

    let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }

    it 'delegates to a relevant service instance' do
      expect_next_instance_of(AutoMerge::MergeWhenPipelineSucceedsService) do |service|
        expect(service).to receive(:process).with(merge_request)
      end

      subject
    end

    context 'when auto merge is not enabled' do
      let(:merge_request) { create(:merge_request) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#cancel' do
    subject { service.cancel(merge_request) }

    let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }

    it 'delegates to a relevant service instance' do
      expect_next_instance_of(AutoMerge::MergeWhenPipelineSucceedsService) do |service|
        expect(service).to receive(:cancel).with(merge_request)
      end

      subject
    end

    context 'when auto merge is not enabled' do
      let(:merge_request) { create(:merge_request) }

      it 'returns error' do
        expect(subject[:message]).to eq("Can't cancel the automatic merge")
        expect(subject[:status]).to eq(:error)
        expect(subject[:http_status]).to eq(406)
      end
    end
  end

  describe '#abort' do
    subject { service.abort(merge_request, error) }

    let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }
    let(:error) { 'an error' }

    it 'delegates to a relevant service instance' do
      expect_next_instance_of(AutoMerge::MergeWhenPipelineSucceedsService) do |service|
        expect(service).to receive(:abort).with(merge_request, error)
      end

      subject
    end

    context 'when auto merge is not enabled' do
      let(:merge_request) { create(:merge_request) }

      it 'returns error' do
        expect(subject[:message]).to eq("Can't abort the automatic merge")
        expect(subject[:status]).to eq(:error)
        expect(subject[:http_status]).to eq(406)
      end
    end
  end
end
