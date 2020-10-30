# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Badge::Coverage::Report do
  let_it_be(:project)  { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

  let_it_be(:builds) do
    [
      create(:ci_build, :success, pipeline: pipeline, coverage: 40, name: 'first'),
      create(:ci_build, :success, pipeline: pipeline, coverage: 60)
    ]
  end

  let(:badge) do
    described_class.new(project, 'master', opts: { job: job_name })
  end

  let(:job_name) { nil }

  describe '#entity' do
    it 'describes a coverage' do
      expect(badge.entity).to eq 'coverage'
    end
  end

  describe '#metadata' do
    it 'returns correct metadata' do
      expect(badge.metadata.image_url).to include 'coverage.svg'
    end
  end

  describe '#template' do
    it 'returns correct template' do
      expect(badge.template.key_text).to eq 'coverage'
    end
  end

  describe '#status' do
    before do
      allow(badge).to receive(:pipeline).and_return(pipeline)
    end

    context 'with no pipeline' do
      let(:pipeline) { nil }

      it 'returns nil' do
        expect(badge.status).to be_nil
      end
    end

    context 'with no job specified' do
      it 'returns the pipeline coverage value' do
        expect(badge.status).to eq(50.00)
      end
    end

    context 'with a blank job name' do
      let(:job_name) { ' ' }

      it 'returns the pipeline coverage value' do
        expect(badge.status).to eq(50.00)
      end
    end

    context 'with an unmatching job name specified' do
      let(:job_name) { 'incorrect name' }

      it 'returns nil' do
        expect(badge.status).to be_nil
      end
    end

    context 'with a matching job name specified' do
      let(:job_name) { 'first' }

      it 'returns the pipeline coverage value' do
        expect(badge.status).to eq(40.00)
      end
    end
  end
end
