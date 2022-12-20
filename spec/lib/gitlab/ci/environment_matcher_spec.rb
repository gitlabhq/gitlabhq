# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::EnvironmentMatcher, feature_category: :continuous_integration do
  describe '#match?' do
    context 'when given pattern is a normal string' do
      subject { described_class.new('production') }

      it 'returns true on an exact match' do
        expect(subject.match?('production')).to eq true
      end

      it 'returns false if not an exact match' do
        expect(subject.match?('productiom')).to eq false
      end
    end

    context 'when given pattern has a wildcard' do
      it 'returns true on wildcard matches', :aggregate_failures do
        expect(described_class.new('review/*').match?('review/123')).to eq true
        expect(described_class.new('review/*/*').match?('review/123/456')).to eq true
        expect(described_class.new('*-this-is-a-pattern-*').match?('abc123-this-is-a-pattern-abc123')).to eq true
      end

      it 'returns false when not a wildcard match', :aggregate_failures do
        expect(described_class.new('review/*').match?('review123')).to eq false
        expect(described_class.new('review/*/*').match?('review/123')).to eq false
        expect(described_class.new('*-this-is-a-pattern-*').match?('abc123-this-is-a-pattern')).to eq false
      end
    end

    context 'when given pattern is nil' do
      subject { described_class.new(nil) }

      it 'always returns false' do
        expect(subject.match?('production')).to eq false
        expect(subject.match?('review/123')).to eq false
      end
    end

    context 'when given pattern is an empty string' do
      subject { described_class.new('') }

      it 'always returns false' do
        expect(subject.match?('production')).to eq false
        expect(subject.match?('review/123')).to eq false
      end
    end
  end
end
