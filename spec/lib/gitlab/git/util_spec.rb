# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Git::Util do
  describe '#count_lines' do
    [
      ["", 0],
      ["foo", 1],
      ["foo\n", 1],
      ["foo\n\n", 2]
    ].each do |string, line_count|
      it "counts #{line_count} lines in #{string.inspect}" do
        expect(described_class.count_lines(string)).to eq(line_count)
      end
    end
  end
end
