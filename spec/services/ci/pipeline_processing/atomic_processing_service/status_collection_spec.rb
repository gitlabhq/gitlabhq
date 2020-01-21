# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelineProcessing::AtomicProcessingService::StatusCollection do
  using RSpec::Parameterized::TableSyntax

  set(:pipeline) { create(:ci_pipeline) }
  set(:build_a) { create(:ci_build, :success, name: 'build-a', stage: 'build', stage_idx: 0, pipeline: pipeline) }
  set(:build_b) { create(:ci_build, :failed, name: 'build-b', stage: 'build', stage_idx: 0, pipeline: pipeline) }
  set(:test_a) { create(:ci_build, :running, name: 'test-a', stage: 'test', stage_idx: 1, pipeline: pipeline) }
  set(:test_b) { create(:ci_build, :pending, name: 'test-b', stage: 'test', stage_idx: 1, pipeline: pipeline) }
  set(:deploy) { create(:ci_build, :created, name: 'deploy', stage: 'deploy', stage_idx: 2, pipeline: pipeline) }

  let(:collection) { described_class.new(pipeline) }

  describe '#set_processable_status' do
    it 'does update existing status of processable' do
      collection.set_processable_status(test_a.id, 'success', 100)

      expect(collection.status_for_names(['test-a'])).to eq('success')
    end

    it 'ignores a missing processable' do
      collection.set_processable_status(-1, 'failed', 100)
    end
  end

  describe '#status_of_all' do
    it 'returns composite status of the collection' do
      expect(collection.status_of_all).to eq('running')
    end
  end

  describe '#status_for_names' do
    where(:names, :status) do
      %w[build-a]         | 'success'
      %w[build-a build-b] | 'failed'
      %w[build-a test-a]  | 'running'
    end

    with_them do
      it 'returns composite status of given names' do
        expect(collection.status_for_names(names)).to eq(status)
      end
    end
  end

  describe '#status_for_prior_stage_position' do
    where(:stage, :status) do
      0 | 'success'
      1 | 'failed'
      2 | 'running'
    end

    with_them do
      it 'returns composite status for processables in prior stages' do
        expect(collection.status_for_prior_stage_position(stage)).to eq(status)
      end
    end
  end

  describe '#status_for_stage_position' do
    where(:stage, :status) do
      0 | 'failed'
      1 | 'running'
      2 | 'created'
    end

    with_them do
      it 'returns composite status for processables at a given stages' do
        expect(collection.status_for_stage_position(stage)).to eq(status)
      end
    end
  end

  describe '#created_processable_ids_for_stage_position' do
    it 'returns IDs of processables at a given stage position' do
      expect(collection.created_processable_ids_for_stage_position(0)).to be_empty
      expect(collection.created_processable_ids_for_stage_position(1)).to be_empty
      expect(collection.created_processable_ids_for_stage_position(2)).to contain_exactly(deploy.id)
    end
  end

  describe '#processing_processables' do
    it 'returns processables marked as processing' do
      expect(collection.processing_processables.map { |processable| processable[:id]} )
        .to contain_exactly(build_a.id, build_b.id, test_a.id, test_b.id, deploy.id)
    end
  end
end
