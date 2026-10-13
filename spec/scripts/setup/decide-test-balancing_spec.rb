# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/stub_env'

require_relative '../../../scripts/setup/decide-test-balancing'

RSpec.describe DecideTestBalancing, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- We use dashes in scripts
  include StubENV

  subject(:decision) { described_class.new }

  before do
    stub_env('CI_MERGE_REQUEST_LABELS', nil)
    stub_env('GLCI_USE_TEST_BALANCING', nil)
  end

  describe '#enabled?' do
    context 'when GLCI_USE_TEST_BALANCING is already set (inherited from parent)' do
      it 'honors true even when the skip label is present' do
        stub_env('GLCI_USE_TEST_BALANCING', 'true')
        stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline:skip-test-balancing')

        expect(decision.enabled?).to be(true)
      end

      it 'honors false' do
        stub_env('GLCI_USE_TEST_BALANCING', 'false')

        expect(decision.enabled?).to be(false)
      end
    end

    context 'when the pipeline:skip-test-balancing label is present' do
      it 'is disabled' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'type::feature,pipeline:skip-test-balancing')

        expect(decision.enabled?).to be(false)
      end
    end

    context 'when no relevant label is present' do
      it 'is enabled by default' do
        expect(decision.enabled?).to be(true)
      end
    end
  end

  describe '#to_dotenv' do
    it 'formats the decision as a dotenv line' do
      expect(decision.to_dotenv).to eq('GLCI_USE_TEST_BALANCING=true')
    end
  end
end
