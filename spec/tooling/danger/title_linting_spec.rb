# frozen_string_literal: true

require 'rspec-parameterized'

require_relative '../../../tooling/danger/title_linting'

RSpec.describe Tooling::Danger::TitleLinting do
  using RSpec::Parameterized::TableSyntax

  describe '#sanitize_mr_title' do
    where(:mr_title, :expected_mr_title) do
      '`My MR title`' | "\\`My MR title\\`"
      'WIP: My MR title' | 'My MR title'
      'Draft: My MR title' | 'My MR title'
      '(Draft) My MR title' | 'My MR title'
      '[Draft] My MR title' | 'My MR title'
      '[DRAFT] My MR title' | 'My MR title'
      'DRAFT: My MR title' | 'My MR title'
      'DRAFT: `My MR title`' | "\\`My MR title\\`"
    end

    with_them do
      subject { described_class.sanitize_mr_title(mr_title) }

      it { is_expected.to eq(expected_mr_title) }
    end
  end

  describe '#remove_draft_flag' do
    where(:mr_title, :expected_mr_title) do
      'WIP: My MR title' | 'My MR title'
      'Draft: My MR title' | 'My MR title'
      '(Draft) My MR title' | 'My MR title'
      '[Draft] My MR title' | 'My MR title'
      '[DRAFT] My MR title' | 'My MR title'
      'DRAFT: My MR title' | 'My MR title'
    end

    with_them do
      subject { described_class.remove_draft_flag(mr_title) }

      it { is_expected.to eq(expected_mr_title) }
    end
  end

  describe '#has_draft_flag?' do
    it 'returns true for a draft title' do
      expect(described_class.has_draft_flag?('Draft: My MR title')).to be true
    end

    it 'returns false for non draft title' do
      expect(described_class.has_draft_flag?('My MR title')).to be false
    end
  end

  describe '#has_cherry_pick_flag?' do
    [
      'Cherry Pick !1234',
      'cherry-pick !1234',
      'CherryPick !1234'
    ].each do |mr_title|
      it 'returns true for cherry-pick title' do
        expect(described_class.has_cherry_pick_flag?(mr_title)).to be true
      end
    end

    it 'returns false for non cherry-pick title' do
      expect(described_class.has_cherry_pick_flag?('My MR title')).to be false
    end
  end

  describe '#has_run_all_rspec_flag?' do
    it 'returns true for a title that includes RUN ALL RSPEC' do
      expect(described_class.has_run_all_rspec_flag?('My MR title RUN ALL RSPEC')).to be true
    end

    it 'returns true for a title that does not include RUN ALL RSPEC' do
      expect(described_class.has_run_all_rspec_flag?('My MR title')).to be false
    end
  end

  describe '#has_run_as_if_foss_flag?' do
    it 'returns true for a title that includes RUN AS-IF-FOSS' do
      expect(described_class.has_run_as_if_foss_flag?('My MR title RUN AS-IF-FOSS')).to be true
    end

    it 'returns true for a title that does not include RUN AS-IF-FOSS' do
      expect(described_class.has_run_as_if_foss_flag?('My MR title')).to be false
    end
  end
end
