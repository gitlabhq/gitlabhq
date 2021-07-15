# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::YamlProcessor::Dag do
  let(:nodes) { {} }

  subject(:result) { described_class.new(nodes).tsort }

  context 'when it is a regular pipeline' do
    let(:nodes) do
      { 'job_c' => %w(job_b job_d), 'job_d' => %w(job_a), 'job_b' => %w(job_a), 'job_a' => %w() }
    end

    it 'returns ordered jobs' do
      expect(result).to eq(%w(job_a job_b job_d job_c))
    end
  end

  context 'when there is a circular dependency' do
    let(:nodes) do
      { 'job_a' => %w(job_c), 'job_b' => %w(job_a), 'job_c' => %w(job_b) }
    end

    it 'raises TSort::Cyclic' do
      expect { result }.to raise_error(TSort::Cyclic, /topological sort failed/)
    end
  end

  context 'when there is a missing job' do
    let(:nodes) do
      { 'job_a' => %w(job_d), 'job_b' => %w(job_a) }
    end

    it 'raises MissingNodeError' do
      expect { result }.to raise_error(
        Gitlab::Ci::YamlProcessor::Dag::MissingNodeError, 'node job_d is missing'
      )
    end
  end
end
