# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DagPipelineSerializer do
  describe '#represent' do
    subject { described_class.new.represent(pipeline) }

    let(:pipeline) { create(:ci_pipeline) }
    let!(:job) { create(:ci_build, pipeline: pipeline) }

    it 'includes stages' do
      expect(subject[:stages]).to be_present
      expect(subject[:stages].size).to eq 1
    end

    it 'matches schema' do
      expect(subject.to_json).to match_schema('entities/dag_pipeline')
    end
  end
end
