# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StagePresenter do
  let(:stage) { create(:ci_stage) }
  let(:presenter) { described_class.new(stage) }

  let!(:build) { create(:ci_build, :tags, :artifacts, pipeline: stage.pipeline, stage: stage.name) }
  let!(:retried_build) { create(:ci_build, :tags, :artifacts, :retried, pipeline: stage.pipeline, stage: stage.name) }

  before do
    create(:generic_commit_status, pipeline: stage.pipeline, ci_stage: stage)
  end

  shared_examples 'preloaded associations for CI status' do
    it 'preloads project' do
      expect(presented_stage.association(:project)).to be_loaded
    end

    it 'preloads build pipeline' do
      expect(presented_stage.association(:pipeline)).to be_loaded
    end

    it 'preloads build tags' do
      expect(presented_stage.association(:tags)).to be_loaded
    end

    it 'preloads build artifacts archive' do
      expect(presented_stage.association(:job_artifacts_archive)).to be_loaded
    end

    it 'preloads build artifacts metadata' do
      expect(presented_stage.association(:metadata)).to be_loaded
    end
  end

  describe '#latest_ordered_statuses' do
    subject(:presented_stage) { presenter.latest_ordered_statuses.second }

    it_behaves_like 'preloaded associations for CI status'
  end

  describe '#retried_ordered_statuses' do
    subject(:presented_stage) { presenter.retried_ordered_statuses.first }

    it_behaves_like 'preloaded associations for CI status'
  end
end
