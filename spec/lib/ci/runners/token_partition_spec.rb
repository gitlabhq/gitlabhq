# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::TokenPartition, feature_category: :continuous_integration do
  describe '.decode' do
    subject(:partition_key) { described_class.new(token).decode }

    context 'for routable token' do
      context 'with group type token' do
        let(:runner) { create(:ci_runner, :group, groups: [create(:group)]) }
        let(:token) { runner.token }

        it { is_expected.to eq('group_type') }
      end

      context 'with project type token' do
        let(:runner) { create(:ci_runner, :project, projects: [create(:project)]) }
        let(:token) { runner.token }

        it { is_expected.to eq('project_type') }
      end

      context 'with invalid token' do
        let(:token) { "glrtr-invalid-token" }

        it { is_expected.to be_nil }
      end
    end

    context 'for legacy token' do
      let(:token) { 't2_JUST20LETTERSANDNUMB' }

      it { is_expected.to eq('group_type') }

      context 'with prefix' do
        let(:token) { 'glrt-t2_JUST20LETTERSANDNUMB' } # gitleaks:allow -- just for test

        it { is_expected.to eq('group_type') }
      end
    end
  end
end
