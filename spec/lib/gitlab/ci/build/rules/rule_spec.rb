# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule do
  let(:seed) do
    double('build seed',
      to_resource: ci_build,
      variables: ci_build.scoped_variables
    )
  end

  let(:pipeline) { create(:ci_pipeline) }
  let(:ci_build) { build(:ci_build, pipeline: pipeline) }
  let(:rule)     { described_class.new(rule_hash) }

  describe '#matches?' do
    subject { rule.matches?(pipeline, seed) }

    context 'with one matching clause' do
      let(:rule_hash) do
        { if: '$VAR == null', when: 'always' }
      end

      it { is_expected.to eq(true) }
    end

    context 'with two matching clauses' do
      let(:rule_hash) do
        { if: '$VAR == null', changes: '**/*', when: 'always' }
      end

      it { is_expected.to eq(true) }
    end

    context 'with a matching and non-matching clause' do
      let(:rule_hash) do
        { if: '$VAR != null', changes: '$VAR == null', when: 'always' }
      end

      it { is_expected.to eq(false) }
    end

    context 'with two non-matching clauses' do
      let(:rule_hash) do
        { if: '$VAR != null', changes: 'README', when: 'always' }
      end

      it { is_expected.to eq(false) }
    end
  end
end
