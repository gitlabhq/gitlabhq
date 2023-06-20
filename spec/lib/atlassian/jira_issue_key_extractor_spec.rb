# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Atlassian::JiraIssueKeyExtractor, feature_category: :integrations do
  describe '.has_keys?' do
    subject { described_class.has_keys?(string) }

    context 'when string contains Jira issue keys' do
      let(:string) { 'Test some string TEST-01 with keys' }

      it { is_expected.to eq(true) }
    end

    context 'when string does not contain Jira issue keys' do
      let(:string) { 'string with no jira issue keys' }

      it { is_expected.to eq(false) }
    end
  end

  describe '#issue_keys' do
    subject { described_class.new('TEST-01 Some A-100 issue title OTHER-02 ABC!-1 that mentions Jira issue').issue_keys }

    it 'returns all valid Jira issue keys' do
      is_expected.to contain_exactly('TEST-01', 'OTHER-02')
    end

    context 'when multiple strings are passed in' do
      subject { described_class.new('TEST-01 Some A-100', 'issue title OTHER', '-02 ABC!-1 that mentions Jira issue').issue_keys }

      it 'returns all valid Jira issue keys in any of those string' do
        is_expected.to contain_exactly('TEST-01')
      end
    end

    context 'with custom_regex' do
      subject { described_class.new('TEST-01 some A-100', custom_regex: /(?<issue>[B-Z]+-\d+)/).issue_keys }

      it 'returns all valid Jira issue keys' do
        is_expected.to contain_exactly('TEST-01')
      end
    end

    context 'with untrusted regex' do
      subject { described_class.new('TEST-01 some A-100', custom_regex: Gitlab::UntrustedRegexp.new("[A-Z]{2,}-\\d+")).issue_keys }

      it 'returns all valid Jira issue keys' do
        is_expected.to contain_exactly('TEST-01')
      end
    end
  end
end
