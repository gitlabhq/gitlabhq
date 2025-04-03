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

  describe 'foreground colors' do
    let(:parser) { described_class.new('test') }

    it 'parses standard foreground colors (30-37)' do
      expect(parser.on_30(nil)).to eq({ fg: 'term-fg-black' })
      expect(parser.on_31(nil)).to eq({ fg: 'term-fg-red' })
      expect(parser.on_32(nil)).to eq({ fg: 'term-fg-green' })
      expect(parser.on_33(nil)).to eq({ fg: 'term-fg-yellow' })
      expect(parser.on_34(nil)).to eq({ fg: 'term-fg-blue' })
      expect(parser.on_35(nil)).to eq({ fg: 'term-fg-magenta' })
      expect(parser.on_36(nil)).to eq({ fg: 'term-fg-cyan' })
      expect(parser.on_37(nil)).to eq({ fg: 'term-fg-white' })
    end

    it 'parses light foreground colors (90-97)' do
      expect(parser.on_90(nil)).to eq({ fg: 'term-fg-l-black' })
      expect(parser.on_91(nil)).to eq({ fg: 'term-fg-l-red' })
      expect(parser.on_92(nil)).to eq({ fg: 'term-fg-l-green' })
      expect(parser.on_93(nil)).to eq({ fg: 'term-fg-l-yellow' })
      expect(parser.on_94(nil)).to eq({ fg: 'term-fg-l-blue' })
      expect(parser.on_95(nil)).to eq({ fg: 'term-fg-l-magenta' })
      expect(parser.on_96(nil)).to eq({ fg: 'term-fg-l-cyan' })
      expect(parser.on_97(nil)).to eq({ fg: 'term-fg-l-white' })
    end

    it 'resets foreground color with 39' do
      expect(parser.on_39(nil)).to eq({ fg: nil })
    end
  end

  describe 'background colors' do
    let(:parser) { described_class.new('test') }

    it 'parses standard background colors (40-47)' do
      expect(parser.on_40(nil)).to eq({ bg: 'term-bg-black' })
      expect(parser.on_41(nil)).to eq({ bg: 'term-bg-red' })
      expect(parser.on_42(nil)).to eq({ bg: 'term-bg-green' })
      expect(parser.on_43(nil)).to eq({ bg: 'term-bg-yellow' })
      expect(parser.on_44(nil)).to eq({ bg: 'term-bg-blue' })
      expect(parser.on_45(nil)).to eq({ bg: 'term-bg-magenta' })
      expect(parser.on_46(nil)).to eq({ bg: 'term-bg-cyan' })
      expect(parser.on_47(nil)).to eq({ bg: 'term-bg-white' })
    end

    it 'parses light background colors (100-107)' do
      expect(parser.on_100(nil)).to eq({ bg: 'term-bg-l-black' })
      expect(parser.on_101(nil)).to eq({ bg: 'term-bg-l-red' })
      expect(parser.on_102(nil)).to eq({ bg: 'term-bg-l-green' })
      expect(parser.on_103(nil)).to eq({ bg: 'term-bg-l-yellow' })
      expect(parser.on_104(nil)).to eq({ bg: 'term-bg-l-blue' })
      expect(parser.on_105(nil)).to eq({ bg: 'term-bg-l-magenta' })
      expect(parser.on_106(nil)).to eq({ bg: 'term-bg-l-cyan' })
      expect(parser.on_107(nil)).to eq({ bg: 'term-bg-l-white' })
    end

    it 'resets background color with 49' do
      expect(parser.on_49(nil)).to eq({ bg: nil })
    end
  end
end
