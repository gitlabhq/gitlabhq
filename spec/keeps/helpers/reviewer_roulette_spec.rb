# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/reviewer_roulette'

RSpec.describe Keeps::Helpers::ReviewerRoulette, feature_category: :tooling do
  let_it_be(:stats) { fixture_file('keeps/helpers/stats.json') }
  let(:roulette) { described_class.new }

  subject(:reviewer) { roulette.random_reviewer_for('maintainer::backend') }

  context 'when request to get stats succeeds' do
    before do
      stub_request(:get, described_class::STATS_JSON_URL).to_return(status: 200, body: stats)
    end

    context 'when reviewers are available' do
      it 'returns the available reviewer for the role' do
        expect(reviewer).to eq('tiera')
      end
    end

    context 'when reviewers are unavailable' do
      before do
        allow(roulette).to receive(:status_available?).at_least(:once).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context 'when there is no matching role' do
      subject(:reviewer) { roulette.random_reviewer_for('unknown role') }

      it { is_expected.to be_nil }
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
end
