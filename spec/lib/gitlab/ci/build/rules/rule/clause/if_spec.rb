# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::If, feature_category: :continuous_integration do
  include StubFeatureFlags

  subject(:if_clause) { described_class.new(expression) }

  describe '#satisfied_by?' do
    let(:context_class) { Gitlab::Ci::Build::Context::Base }
    let(:rules_context) { instance_double(context_class, variables_hash: {}) }

    subject(:satisfied_by?) { if_clause.satisfied_by?(nil, rules_context) }

    context 'when expression is a basic string comparison' do
      context 'when comparison is true' do
        let(:expression) { '"value" == "value"' }

        it { is_expected.to eq(true) }
      end

      context 'when comparison is false' do
        let(:expression) { '"value" == "other"' }

        it { is_expected.to eq(false) }
      end
    end

    context 'when expression is a regexp' do
      context 'when comparison is true' do
        let(:expression) { '"abcde" =~ /^ab.*/' }

        it { is_expected.to eq(true) }
      end

      context 'when comparison is false' do
        let(:expression) { '"abcde" =~ /^af.*/' }

        it { is_expected.to eq(false) }
      end

      context 'when both side of the expression are variables' do
        let(:expression) { '$teststring =~ $pattern' }

        context 'when comparison is true' do
          let(:rules_context) do
            instance_double(context_class, variables_hash: { 'teststring' => 'abcde', 'pattern' => '/^ab.*/' })
          end

          it { is_expected.to eq(true) }
        end

        context 'when comparison is false' do
          let(:rules_context) do
            instance_double(context_class, variables_hash: { 'teststring' => 'abcde', 'pattern' => '/^af.*/' })
          end

          it { is_expected.to eq(false) }
        end
      end
    end
  end
end
