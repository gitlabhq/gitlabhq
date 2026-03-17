# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SupplyChain, feature_category: :artifact_security do
  describe '.publish_provenance_for_build?' do
    subject(:query) { described_class.publish_provenance_for_build?(build) }

    include_context 'with build, pipeline and artifacts'

    before do
      allow(described_class).to receive_messages(publish_container_provenance?: publish_container_provenance,
        publish_artifact_provenance?: publish_artifact_provenance)
    end

    let(:publish_container_provenance) { false }
    let(:publish_artifact_provenance) { false }

    context 'with nil build' do
      let(:build) { nil }

      it { is_expected.to be_falsy }
    end

    context 'when publish methods are true' do
      let(:publish_container_provenance) { true }
      let(:publish_artifact_provenance) { true }

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

      context 'without build artifacts' do
        let(:build) do
          create(:ci_build, :finished, project: project)
        end

        it { is_expected.to be_falsy }
      end

      context "without stage name 'build'" do
        let(:build) do
          create(:ci_build, :slsa_artifacts, :finished, runner_manager: runner_manager, pipeline: pipeline,
            stage: "test")
        end

        it { is_expected.to be_falsy }
      end
    end

    context 'when both publish methods are false' do
      it { is_expected.to be_falsy }
    end

    context 'when at least one publish_method is true' do
      context 'if publish_container_provenance is true' do
        let(:publish_container_provenance) { true }

        it { is_expected.to be_truthy }
      end

      context 'if publish_artifact_provenance is true' do
        let(:publish_artifact_provenance) { true }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.yaml_variable_truthy?' do
    subject(:query) { described_class.send(:yaml_variable_truthy?, build, variable) }

    let(:variable) { "VAR" }
    let(:variable_value) { "test.test.test" }

    context 'with a valid build that has yaml_variables' do
      let(:yaml_variables) do
        [
          { key: 'TEST_VAR', value: variable_value, public: true }
        ]
      end

      let(:build) do
        create(:ci_build, :slsa_artifacts, :finished, stage: "build")
      end

      before do
        stub_ci_job_definition(build, yaml_variables: yaml_variables)
      end

      context "and variable exists" do
        let(:variable) { "TEST_VAR" }

        context "and is truthy" do
          it { is_expected.to be_truthy }
        end

        context "and is the string 'false'" do
          let(:variable_value) { "false" }

          it { is_expected.to be_falsy }
        end

        context "and is the string '0'" do
          let(:variable_value) { "0" }

          it { is_expected.to be_falsy }
        end

        context "and is the string 'true'" do
          let(:variable_value) { "true" }

          it { is_expected.to be_truthy }
        end
      end

      context "and variable does not exist" do
        let(:variable) { "NON_EXISTENT_VAR" }

        it { is_expected.to be_falsy }
      end
    end

    context 'with literal nil yaml_variables' do
      let(:build) do
        build = instance_double(Ci::Build)
        allow(build).to receive(:yaml_variables).and_return(nil)
        build
      end

      it { is_expected.to be_falsy }
    end

    context 'with empty array of yaml_variables' do
      include_context 'with build, pipeline and artifacts'

      let(:yaml_variables) { [] }

      it { is_expected.to be_falsy }
    end
  end

  describe '.publish_artifact_provenance?' do
    subject(:query) { described_class.publish_artifact_provenance?(build) }

    include_context 'with build, pipeline and artifacts'

    context 'when a valid build that requires attestation is passed' do
      it { is_expected.to be_truthy }
    end

    context 'without CI variable ATTEST_BUILD_ARTIFACTS' do
      let(:yaml_variables) { [] }

      it { is_expected.to be_falsy }
    end
  end

  describe '.publish_container_provenance?' do
    subject(:query) { described_class.publish_container_provenance?(build) }

    let_it_be(:project, reload: true) { create_default(:project, :public, :repository) }

    context "with a valid build that requires an attestation" do
      let(:yaml_variables) do
        [
          { key: 'ATTEST_CONTAINER_IMAGES', value: 'true', public: true },
          { key: 'IMAGE_DIGEST', value: '5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa',
            public: true }
        ]
      end

      let(:build) do
        create(:ci_build, :slsa_artifacts, :finished, stage: "build")
      end

      before do
        stub_ci_job_definition(build, yaml_variables: yaml_variables)
      end

      it { is_expected.to be_truthy }
    end

    context 'without the required variables' do
      let(:build) do
        create(:ci_build, :finished, project: project, stage: "build")
      end

      before do
        stub_ci_job_definition(build, yaml_variables: yaml_variables) if yaml_variables
      end

      context 'if both variables are missing' do
        let(:yaml_variables) { [] }

        it { is_expected.to be_falsy }
      end

      context 'if only ATTEST_CONTAINER_IMAGES is present' do
        let(:yaml_variables) do
          [
            { key: 'ATTEST_CONTAINER_IMAGES', value: 'true', public: true }
          ]
        end

        it { is_expected.to be_falsy }
      end

      context 'if only IMAGE_DIGEST is present' do
        let(:yaml_variables) do
          [
            { key: 'IMAGE_DIGEST', value: '5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa',
              public: true }
          ]
        end

        it { is_expected.to be_falsy }
      end
    end
  end
end
