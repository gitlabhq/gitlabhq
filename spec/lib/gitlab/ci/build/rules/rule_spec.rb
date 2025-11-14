# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule do
  let(:seed) do
    double('build seed',
      to_resource: ci_build,
      variables_hash: ci_build.scoped_variables.to_hash
    )
  end

  let(:pipeline) { create(:ci_pipeline) }
  let(:ci_build) { build(:ci_build, pipeline: pipeline) }
  let(:rule)     { described_class.new(rule_hash) }

  before do
    allow(pipeline).to receive(:modified_paths).and_return(['file.rb'])
  end

  describe '#matches?' do
    subject { rule.matches?(pipeline, seed) }

    context 'with one matching clause if' do
      let(:rule_hash) do
        { if: '$VAR == null', when: 'always' }
      end

      it { is_expected.to eq(true) }
    end

    context 'with one matching clause changes' do
      let(:rule_hash) do
        { changes: { paths: ['**/*'] }, when: 'always' }
      end

      it { is_expected.to eq(true) }
    end

    context 'with two matching clauses' do
      let(:rule_hash) do
        { if: '$VAR == null', changes: { paths: ['**/*'] }, when: 'always' }
      end

      it { is_expected.to eq(true) }
    end

    context 'with a matching and non-matching clause' do
      let(:rule_hash) do
        { if: '$VAR != null', changes: { paths: ['invalid.xyz'] }, when: 'always' }
      end

      it { is_expected.to eq(false) }
    end

    context 'with two non-matching clauses' do
      let(:rule_hash) do
        { if: '$VAR != null', changes: { paths: ['README'] }, when: 'always' }
      end

      it { is_expected.to eq(false) }
    end
  end
end
