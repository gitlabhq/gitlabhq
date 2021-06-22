# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::MarkdownText do
  describe '.format' do
    it 'formats the text' do
      author = double(:author, login: 'Alice')
      text = described_class.format('Hello', author)

      expect(text).to eq("*Created by: Alice*\n\nHello")
    end
  end

  describe '#to_s' do
    it 'returns the text when the author was found' do
      author = double(:author, login: 'Alice')
      text = described_class.new('Hello', author, true)

      expect(text.to_s).to eq('Hello')
    end

    it 'returns the text when the author has no login' do
      author = double(:author, login: nil)
      text = described_class.new('Hello', author, true)

      expect(text.to_s).to eq('Hello')
    end

    it 'returns empty text when it receives nil' do
      author = double(:author, login: nil)
      text = described_class.new(nil, author, true)

      expect(text.to_s).to eq('')
    end

    it 'returns the text with an extra header when the author was not found' do
      author = double(:author, login: 'Alice')
      text = described_class.new('Hello', author)

      expect(text.to_s).to eq("*Created by: Alice*\n\nHello")
    end

    it 'cleans invalid chars' do
      author = double(:author, login: 'Alice')
      text = described_class.format("\u0000Hello", author)

      expect(text.to_s).to eq("*Created by: Alice*\n\nHello")
    end
  end
end
