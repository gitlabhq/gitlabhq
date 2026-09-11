# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Ci::EnvironmentMatcher, feature_category: :continuous_integration do
  describe '#match?' do
    context 'when given pattern is a normal string' do
      subject { described_class.new('production') }

      it 'returns true on an exact match' do
        expect(subject.match?('production')).to be true
      end

      it 'returns false if not an exact match' do
        expect(subject.match?('productiom')).to be false
      end
    end

    context 'when given pattern has a wildcard' do
      using RSpec::Parameterized::TableSyntax

      where(:pattern, :environment, :matches) do
        [
          ['review/*', 'review/123', true],
          ['review/*', 'review/feature-branch', true],
          ['review/*/*', 'review/123/456', true],
          ['*-this-is-a-pattern-*', 'abc123-this-is-a-pattern-abc123', true],
          ['prod*', 'production', true],
          ['*', 'anything-goes', true],
          ['*', '', true],
          ['review/*/*', 'review/123', false],
          ['*-this-is-a-pattern-*', 'abc123-this-is-a-pattern', false],
          ['review/*', 'review123', false],
          ['review/*', 'not-review/app1', false],
          ['review/*', 'staging-review/test', false],
          ['prod*', 'not-prod-thing', false],
          ['prod.internal*', 'prodXinternal-app', false],
          # environment_scope values aren't schema-validated, so patterns can
          # contain unescaped regex metacharacters like `[`.
          ['prod[*', 'prod[abc', true],
          ['prod*', "production\nmalicious", false]
        ]
      end

      with_them do
        it 'matches as expected' do
          expect(described_class.new(pattern).match?(environment)).to eq matches
        end
      end
    end

    context 'when given pattern is nil' do
      subject { described_class.new(nil) }

      it 'always returns false' do
        expect(subject.match?('production')).to be false
        expect(subject.match?('review/123')).to be false
      end
    end

    context 'when given pattern is an empty string' do
      subject { described_class.new('') }

      it 'always returns false' do
        expect(subject.match?('production')).to be false
        expect(subject.match?('review/123')).to be false
      end
    end
  end
end
