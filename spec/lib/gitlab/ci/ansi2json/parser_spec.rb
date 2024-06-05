# frozen_string_literal: true

require 'fast_spec_helper'

# The rest of the specs for this class are covered in style_spec.rb
RSpec.describe Gitlab::Ci::Ansi2json::Parser, feature_category: :continuous_integration do
  subject { described_class }

  describe 'bold?' do
    it 'returns true if style mask matches bold format' do
      expect(subject.bold?(0x01)).to be_truthy
    end

    it 'returns false if style mask does not match bold format' do
      expect(subject.bold?(0x02)).to be_falsey
    end
  end

  describe 'matching_formats' do
    it 'returns matching formats given a style mask' do
      expect(subject.matching_formats(0x01)).to eq(%w[term-bold])
      expect(subject.matching_formats(0x03)).to eq(%w[term-bold term-italic])
      expect(subject.matching_formats(0x07)).to eq(%w[term-bold term-italic term-underline])
    end

    it 'returns an empty array if no formats match the style mask' do
      expect(subject.matching_formats(0)).to eq([])
    end
  end
end
