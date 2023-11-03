# frozen_string_literal: true

require 'fast_spec_helper'
require 'tsort'

RSpec.describe Gitlab::Ci::YamlProcessor::Dag, feature_category: :pipeline_composition do
  let(:nodes) { {} }

  subject(:result) { described_class.new(nodes).tsort }

  context 'when it is a regular pipeline' do
    let(:nodes) do
      { 'job_c' => %w[job_b job_d], 'job_d' => %w[job_a], 'job_b' => %w[job_a], 'job_a' => %w[] }
    end

    it 'returns ordered jobs' do
      expect(result).to eq(%w[job_a job_b job_d job_c])
    end
  end

  context 'when there is a circular dependency' do
    let(:nodes) do
      { 'job_a' => %w[job_c], 'job_b' => %w[job_a], 'job_c' => %w[job_b] }
    end

    it 'raises TSort::Cyclic error' do
      expect { result }.to raise_error(TSort::Cyclic, /topological sort failed/)
    end

    context 'when a job has a self-dependency' do
      let(:nodes) do
        { 'job_a' => %w[job_a] }
      end

      it 'raises TSort::Cyclic error' do
        expect { result }.to raise_error(TSort::Cyclic, "self-dependency: job_a")
      end
    end
  end

  context 'when there are some missing jobs' do
    let(:nodes) do
      { 'job_a' => %w[job_d job_f], 'job_b' => %w[job_a job_c job_e] }
    end

    it 'ignores the missing ones and returns in a valid order' do
      expect(result).to eq(%w[job_d job_f job_a job_c job_e job_b])
    end
  end
end
