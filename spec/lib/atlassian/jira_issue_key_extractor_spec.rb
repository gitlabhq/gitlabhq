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
    using RSpec::Parameterized::TableSyntax

    where(:texts, :options, :expected_keys) do
      # Default extraction from a single message: valid keys are returned;
      # malformed keys (A-100, ABC!-1) are skipped.
      [
        'TEST-01 Some A-100 issue title OTHER-02 ABC!-1 that mentions Jira issue'
      ] | {} | %w[TEST-01 OTHER-02]

      # Multiple strings are scanned independently; a key split across two
      # arguments is not reassembled.
      [
        'TEST-01 Some A-100', 'issue title OTHER', '-02 ABC!-1 that mentions Jira issue'
      ] | {} | %w[TEST-01]

      # A custom Ruby regex overrides the default pattern.
      ['TEST-01 some A-100'] | { custom_regex: /(?<issue>[B-Z]+-\d+)/ } | %w[TEST-01]

      # A custom Gitlab::UntrustedRegexp (RE2) is also supported.
      ['TEST-01 some A-100'] | { custom_regex: Gitlab::UntrustedRegexp.new('[A-Z]{2,}-\d+') } | %w[TEST-01]

      # Non-ASCII (CJK, accented Latin, emoji): the bug this MR fixes.
      ['提交JIRA-123'] | {} | ['JIRA-123']
      ['JIRA-123 を修正'] | {} | ['JIRA-123']
      ['cafèJIRA-123'] | {} | ['JIRA-123']
      ['🚀 Fix JIRA-123'] | {} | ['JIRA-123']
      ['🚀JIRA-123 done'] | {} | ['JIRA-123']
      ['修正JIRA-1 と TEST-22'] | {} | %w[JIRA-1 TEST-22]

      # ASCII word characters before the key must NOT match (preserved
      # from the original \b semantics).
      ['5JIRA-123'] | {} | []
      ['_JIRA-123'] | {} | []
      ['fooJIRA-123'] | {} | []
      ['FOOJIRA-123'] | {} | ['FOOJIRA-123']
      ['AJIRA-123'] | {} | ['AJIRA-123']

      # ASCII non-word characters before the key must match.
      ['-JIRA-123'] | {} | ['JIRA-123']
      ['(JIRA-123)'] | {} | ['JIRA-123']
      ['JIRA-123-FOO-456'] | {} | %w[JIRA-123 FOO-456]
      ['MYPROJ-1JIRA-123'] | {} | ['MYPROJ-1']
    end

    with_them do
      it 'extracts the expected Jira issue keys' do
        expect(described_class.new(*texts, **options).issue_keys).to match_array(expected_keys)
      end
    end
  end
end
