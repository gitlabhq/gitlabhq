# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::ImportFormatter do
  let(:formatter) { described_class.new }

  describe '#comment' do
    it 'creates the correct string' do
      expect(formatter.comment('Name', '2020-02-02', 'some text')).to eq(
        "\n\n*By Name on 2020-02-02*\n\nsome text"
      )
    end
  end

  describe '#author_line' do
    it 'returns the correct string with provided author name' do
      expect(formatter.author_line('Name')).to eq("*Created by: Name*\n\n")
    end

    it 'returns the correct string with Anonymous name if author not provided' do
      expect(formatter.author_line(nil)).to eq("*Created by: Anonymous*\n\n")
    end
  end

  describe '#assignee_line' do
    it 'returns the correct string with provided author name' do
      expect(formatter.assignee_line('Name')).to eq("*Assigned to: Name*\n\n")
    end

    it 'returns the correct string with Anonymous name if author not provided' do
      expect(formatter.assignee_line(nil)).to eq("*Assigned to: Anonymous*\n\n")
    end
  end
end
