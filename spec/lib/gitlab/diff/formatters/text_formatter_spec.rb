# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Diff::Formatters::TextFormatter do
  let!(:base) do
    {
      base_sha: 123,
      start_sha: 456,
      head_sha: 789,
      old_path: 'old_path.txt',
      new_path: 'new_path.txt',
      file_identifier_hash: '777',
      line_range: nil
    }
  end

  let!(:complete) do
    base.merge(old_line: 1, new_line: 2)
  end

  it_behaves_like "position formatter" do
    let(:base_attrs) { base }

    let(:attrs) { complete }
  end

  # Specific text formatter examples
  let!(:formatter) { described_class.new(attrs) }
  let(:attrs) { base }

  describe '#line_age' do
    subject { formatter.line_age }

    context ' when there is only new_line' do
      let(:attrs) { base.merge(new_line: 1) }

      it { is_expected.to eq('new') }
    end

    context ' when there is only old_line' do
      let(:attrs) { base.merge(old_line: 1) }

      it { is_expected.to eq('old') }
    end
  end

  describe "#==" do
    it "is false when the line_range changes" do
      formatter_1 = described_class.new(base.merge(line_range: { start_line_code: "foo", end_line_code: "bar" }))
      formatter_2 = described_class.new(base.merge(line_range: { start_line_code: "foo", end_line_code: "baz" }))

      expect(formatter_1).not_to eq(formatter_2)
    end

    it "is true when the line_range doesn't change" do
      attrs = base.merge({ line_range: { start_line_code: "foo", end_line_code: "baz" } })
      formatter_1 = described_class.new(attrs)
      formatter_2 = described_class.new(attrs)

      expect(formatter_1).to eq(formatter_2)
    end
  end
end
