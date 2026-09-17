# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/stub_env'

require_relative '../../../scripts/setup/decide-test-balancing'

RSpec.describe DecideTestBalancing, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- We use dashes in scripts
  include StubENV

  subject(:decision) { described_class.new }

  before do
    stub_env('CI_MERGE_REQUEST_LABELS', nil)
    stub_env('CI_PIPELINE_ID', nil)
    stub_env('GLCI_USE_TEST_BALANCING', nil)
  end

  describe '#enabled?' do
    context 'when GLCI_USE_TEST_BALANCING is already set (inherited from parent)' do
      it 'honors true without re-rolling' do
        stub_env('GLCI_USE_TEST_BALANCING', 'true')
        stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline:skip-test-balancing')

        expect(decision).not_to receive(:sampled?)
        expect(decision.enabled?).to be(true)
      end

      it 'honors false without re-rolling' do
        stub_env('GLCI_USE_TEST_BALANCING', 'false')
        stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline:use-test-balancing')

        expect(decision).not_to receive(:sampled?)
        expect(decision.enabled?).to be(false)
      end
    end

    context 'when the pipeline:use-test-balancing label is present' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', 'type::feature,pipeline:use-test-balancing')
      end

      it 'is enabled regardless of sampling' do
        allow(decision).to receive(:rand).and_return(0.99)

        expect(decision.enabled?).to be(true)
      end
    end

    context 'when the pipeline:skip-test-balancing label is present' do
      it 'is disabled even when the roll would enable it' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'type::feature,pipeline:skip-test-balancing')
        allow(decision).to receive(:rand).and_return(0.0)

        expect(decision.enabled?).to be(false)
      end

      it 'wins over the pipeline:use-test-balancing label' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline:use-test-balancing,pipeline:skip-test-balancing')

        expect(decision.enabled?).to be(false)
      end
    end

    context 'when no relevant label is present and CI_PIPELINE_ID is absent' do
      it 'is enabled when the roll falls within the rollout ratio' do
        allow(decision).to receive(:rand).and_return(0.59)

        expect(decision.enabled?).to be(true)
      end

      it 'is disabled when the roll falls outside the rollout ratio' do
        allow(decision).to receive(:rand).and_return(0.6)

        expect(decision.enabled?).to be(false)
      end
    end

    context 'when sampling on CI_PIPELINE_ID' do
      it 'is deterministic for the same pipeline id' do
        stub_env('CI_PIPELINE_ID', '123456')

        expect(decision.enabled?).to eq(described_class.new.enabled?)
      end
    end
  end

  describe '#to_dotenv' do
    it 'formats the decision as a dotenv line' do
      allow(decision).to receive(:rand).and_return(0.0)

      expect(decision.to_dotenv).to eq('GLCI_USE_TEST_BALANCING=true')
    end
  end
end
