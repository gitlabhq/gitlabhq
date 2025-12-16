# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SupplyChain, feature_category: :artifact_security do
  describe '.publish_provenance_for_build?' do
    subject(:query) { described_class.publish_provenance_for_build?(build) }

    include_context 'with build, pipeline and artifacts'

    it { is_expected.to be_truthy }

    context 'without feature flag' do
      before do
        stub_feature_flags(slsa_provenance_statement: false)
      end

      it { is_expected.to be_falsy }
    end

    context 'with private project' do
      let(:project) { create_default(:project, :private, :repository, group: group) }
      let(:build) do
        create(:ci_build, project: project)
      end

      it { is_expected.to be_falsy }
    end

    context 'without CI variable ATTEST_BUILD_ARTIFACTS' do
      let(:yaml_variables) { [] }

      it { is_expected.to be_falsy }
    end

    context 'without build artifacts' do
      let(:build) do
        create(:ci_build, :finished, project: project)
      end

      it { is_expected.to be_falsy }
    end

    context "without stage name 'build'" do
      let(:build) do
        create(:ci_build, :slsa_artifacts, :finished,
          runner_manager: runner_manager, pipeline: pipeline, stage: "test")
      end

      it { is_expected.to be_falsy }
    end
  end
end
