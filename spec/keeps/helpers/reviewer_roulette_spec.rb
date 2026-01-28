# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/reviewer_roulette'

RSpec.describe Keeps::Helpers::ReviewerRoulette, feature_category: :tooling do
  let_it_be(:stats) { fixture_file('keeps/helpers/stats.json') }
  let(:roulette) { described_class.instance }

  subject(:reviewer) { roulette.random_reviewer_for('maintainer::backend') }

  before do
    # Reset singleton to create a fresh instance
    Singleton.__init__(described_class)

    stub_request(:get, described_class::STATS_JSON_URL).to_return(status: 200, body: stats)
  end

  it 'is a singleton' do
    expect(roulette).to be_a(Singleton)
  end

  context 'when request to get stats succeeds' do
    context 'when reviewers are available' do
      it 'returns the available reviewer for the role' do
        expect(reviewer).to be_present
      end
    end

    context 'when reviewers are unavailable' do
      before do
        allow(roulette).to receive(:available_reviewers).and_return([])
      end

      it { is_expected.to be_nil }
    end

    context 'when there is no matching role' do
      subject(:reviewer) { roulette.random_reviewer_for('unknown role') }

      it { is_expected.to be_nil }
    end

    context 'when identifiers are provided' do
      let(:identifiers) { %w[identifier1 identifier2] }

      subject(:reviewer) { roulette.random_reviewer_for('maintainer::backend', identifiers: identifiers) }

      it 'returns a deterministic reviewer based on identifiers' do
        first_result = roulette.random_reviewer_for('maintainer::backend', identifiers: identifiers)
        second_result = roulette.random_reviewer_for('maintainer::backend', identifiers: identifiers)

        expect(first_result).to eq(second_result)
      end

      it 'returns different reviewers for different identifiers' do
        result_with_identifiers = roulette.random_reviewer_for('maintainer::backend', identifiers: identifiers)
        result_with_other_identifiers = roulette.random_reviewer_for('maintainer::backend',
          identifiers: %w[identifier1 identifier3])

        expect(result_with_identifiers).not_to eq(result_with_other_identifiers)
      end
    end
  end

  context 'when get request raises an error' do
    let_it_be(:error_code) { 404 }
    let_it_be(:error_message) { { message: 'not found' }.to_json }

    before do
      stub_request(:get, described_class::STATS_JSON_URL).to_return(status: error_code, body: error_message)
    end

    it 'raises an error' do
      message = "Failed to get roulette stats with response code: #{error_code} and body:\n#{error_message}"
      expect { reviewer }.to raise_error(Keeps::Helpers::ReviewerRoulette::Error, message)
    end
  end

  describe '#reviewer_available?' do
    let(:username) { 'tiera' }

    subject(:available) { roulette.reviewer_available?(username) }

    context 'when reviewer is available' do
      it { is_expected.to be true }
    end

    context 'when reviewer is not available' do
      let(:username) { 'dora' }

      it { is_expected.to be false }
    end

    context 'when reviewer does not exist' do
      let(:username) { 'nonexistent_user' }

      it { is_expected.to be false }
    end
  end
end
