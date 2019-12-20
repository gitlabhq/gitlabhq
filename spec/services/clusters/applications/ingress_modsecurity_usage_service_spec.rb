# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::IngressModsecurityUsageService do
  describe '#execute' do
    ADO_MODSEC_KEY = Clusters::Applications::IngressModsecurityUsageService::ADO_MODSEC_KEY

    let(:project_with_ci_var) { create(:environment).project }
    let(:project_with_pipeline_var) { create(:environment).project }

    subject { described_class.new.execute }

    context 'with multiple projects' do
      let(:pipeline1) { create(:ci_pipeline, :with_job, project: project_with_pipeline_var) }
      let(:pipeline2) { create(:ci_pipeline, :with_job, project: project_with_ci_var) }

      let!(:deployment_with_pipeline_var) do
        create(
          :deployment,
          :success,
          environment: project_with_pipeline_var.environments.first,
          project: project_with_pipeline_var,
          deployable: pipeline1.builds.last
        )
      end
      let!(:deployment_with_project_var) do
        create(
          :deployment,
          :success,
          environment: project_with_ci_var.environments.first,
          project: project_with_ci_var,
          deployable: pipeline2.builds.last
        )
      end

      context 'mixed data' do
        let!(:ci_variable) { create(:ci_variable, project: project_with_ci_var, key: ADO_MODSEC_KEY, value: "On") }
        let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline1, key: ADO_MODSEC_KEY, value: "Off") }

        it 'gathers variable data' do
          expect(subject[:ingress_modsecurity_blocking]).to eq(1)
          expect(subject[:ingress_modsecurity_disabled]).to eq(1)
        end
      end

      context 'blocking' do
        let(:modsec_values) { { key: ADO_MODSEC_KEY, value: "On" } }

        let!(:ci_variable) { create(:ci_variable, project: project_with_ci_var, **modsec_values) }
        let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline1, **modsec_values) }

        it 'gathers variable data' do
          expect(subject[:ingress_modsecurity_blocking]).to eq(2)
          expect(subject[:ingress_modsecurity_disabled]).to eq(0)
        end
      end

      context 'disabled' do
        let(:modsec_values) { { key: ADO_MODSEC_KEY, value: "Off" } }

        let!(:ci_variable) { create(:ci_variable, project: project_with_ci_var, **modsec_values) }
        let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline1, **modsec_values) }

        it 'gathers variable data' do
          expect(subject[:ingress_modsecurity_blocking]).to eq(0)
          expect(subject[:ingress_modsecurity_disabled]).to eq(2)
        end
      end
    end

    context 'when set as both ci and pipeline variables' do
      let(:modsec_values) { { key: ADO_MODSEC_KEY, value: "Off" } }

      let(:pipeline) { create(:ci_pipeline, :with_job, project: project_with_ci_var) }
      let!(:deployment) do
        create(
          :deployment,
          :success,
          environment: project_with_ci_var.environments.first,
          project: project_with_ci_var,
          deployable: pipeline.builds.last
        )
      end

      let!(:ci_variable) { create(:ci_variable, project: project_with_ci_var, **modsec_values) }
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline, **modsec_values) }

      it 'wont double-count projects' do
        expect(subject[:ingress_modsecurity_blocking]).to eq(0)
        expect(subject[:ingress_modsecurity_disabled]).to eq(1)
      end

      it 'gives precedence to pipeline variable' do
        pipeline_variable.update(value: "On")

        expect(subject[:ingress_modsecurity_blocking]).to eq(1)
        expect(subject[:ingress_modsecurity_disabled]).to eq(0)
      end
    end

    context 'when a project has multiple environments' do
      let(:modsec_values) { { key: ADO_MODSEC_KEY, value: "On" } }

      let!(:env1) { project_with_pipeline_var.environments.first }
      let!(:env2) { create(:environment, project: project_with_pipeline_var) }

      let!(:pipeline_with_2_deployments) do
        create(:ci_pipeline, :with_job, project: project_with_ci_var).tap do |pip|
          pip.builds << build(:ci_build, pipeline: pip, project: project_with_pipeline_var)
        end
      end

      let!(:deployment1) do
        create(
          :deployment,
          :success,
          environment: env1,
          project: project_with_pipeline_var,
          deployable: pipeline_with_2_deployments.builds.last
        )
      end
      let!(:deployment2) do
        create(
          :deployment,
          :success,
          environment: env2,
          project: project_with_pipeline_var,
          deployable: pipeline_with_2_deployments.builds.last
        )
      end

      context 'when set as ci variable' do
        let!(:ci_variable) { create(:ci_variable, project: project_with_pipeline_var, **modsec_values) }

        it 'gathers variable data' do
          expect(subject[:ingress_modsecurity_blocking]).to eq(2)
          expect(subject[:ingress_modsecurity_disabled]).to eq(0)
        end
      end

      context 'when set as pipeline variable' do
        let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline_with_2_deployments, **modsec_values) }

        it 'gathers variable data' do
          expect(subject[:ingress_modsecurity_blocking]).to eq(2)
          expect(subject[:ingress_modsecurity_disabled]).to eq(0)
        end
      end
    end

    context 'when an environment has multiple deployments' do
      let!(:env) { project_with_pipeline_var.environments.first }

      let!(:pipeline_first) do
        create(:ci_pipeline, :with_job, project: project_with_pipeline_var).tap do |pip|
          pip.builds << build(:ci_build, pipeline: pip, project: project_with_pipeline_var)
        end
      end
      let!(:pipeline_last) do
        create(:ci_pipeline, :with_job, project: project_with_pipeline_var).tap do |pip|
          pip.builds << build(:ci_build, pipeline: pip, project: project_with_pipeline_var)
        end
      end

      let!(:deployment_first) do
        create(
          :deployment,
          :success,
          environment: env,
          project: project_with_pipeline_var,
          deployable: pipeline_first.builds.last
        )
      end
      let!(:deployment_last) do
        create(
          :deployment,
          :success,
          environment: env,
          project: project_with_pipeline_var,
          deployable: pipeline_last.builds.last
        )
      end

      context 'when set as pipeline variable' do
        let!(:first_pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline_first, key: ADO_MODSEC_KEY, value: "On") }
        let!(:last_pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline_last, key: ADO_MODSEC_KEY, value: "Off") }

        it 'gives precedence to latest deployment' do
          expect(subject[:ingress_modsecurity_blocking]).to eq(0)
          expect(subject[:ingress_modsecurity_disabled]).to eq(1)
        end
      end
    end
  end
end
