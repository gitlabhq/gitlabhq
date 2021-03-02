# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WordDiff::Segments::DiffHunk do
  subject(:diff_hunk) { described_class.new(line) }

  let(:line) { '@@ -3,14 +4,13 @@' }

  describe '#pos_old' do
    subject { diff_hunk.pos_old }

    it { is_expected.to eq 3 }

    context 'when diff hunk is broken' do
      let(:line) { '@@ ??? @@' }

      it { is_expected.to eq 0 }
    end
  end

  describe '#pos_new' do
    subject { diff_hunk.pos_new }

    it { is_expected.to eq 4 }

    context 'when diff hunk is broken' do
      let(:line) { '@@ ??? @@' }

      it { is_expected.to eq 0 }
    end
  end

  describe '#first_line?' do
    subject { diff_hunk.first_line? }

    it { is_expected.to be_falsey }

    context 'when diff hunk located on the first line' do
      let(:line) { '@@ -1,14 +1,13 @@' }

      it { is_expected.to be_truthy }
    end
  end

  describe '#to_s' do
    subject { diff_hunk.to_s }

    it { is_expected.to eq(line) }
  end
end
