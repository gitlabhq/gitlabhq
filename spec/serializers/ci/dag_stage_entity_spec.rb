# frozen_string_literal: true

require 'spec_helper'

describe Ci::DagStageEntity do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:request) { double(:request) }

  let(:stage) { build(:ci_stage, pipeline: pipeline, name: 'test') }
  let(:entity) { described_class.new(stage, request: request) }

  let!(:job) { create(:ci_build, :success, pipeline: pipeline) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains valid name' do
      expect(subject[:name]).to eq 'test'
    end

    it 'contains the job groups' do
      expect(subject).to include :groups
      expect(subject[:groups]).not_to be_empty

      job_group = subject[:groups].first
      expect(job_group[:name]).to eq 'test'
      expect(job_group[:size]).to eq 1
      expect(job_group[:jobs]).not_to be_empty
    end
  end
end
