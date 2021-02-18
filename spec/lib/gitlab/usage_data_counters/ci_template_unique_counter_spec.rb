# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::CiTemplateUniqueCounter do
  describe '.track_unique_project_event' do
    using RSpec::Parameterized::TableSyntax

    where(:template, :config_source, :expected_event) do
      # Implicit Auto DevOps usage
      'Auto-DevOps.gitlab-ci.yml'                     | :auto_devops_source | 'p_ci_templates_implicit_auto_devops'
      'Jobs/Build.gitlab-ci.yml'                      | :auto_devops_source | 'p_ci_templates_implicit_auto_devops_build'
      'Jobs/Deploy.gitlab-ci.yml'                     | :auto_devops_source | 'p_ci_templates_implicit_auto_devops_deploy'
      'Security/SAST.gitlab-ci.yml'                   | :auto_devops_source | 'p_ci_templates_implicit_security_sast'
      'Security/Secret-Detection.gitlab-ci.yml'       | :auto_devops_source | 'p_ci_templates_implicit_security_secret_detection'
      # Explicit include:template usage
      '5-Minute-Production-App.gitlab-ci.yml'         | :repository_source  | 'p_ci_templates_5_min_production_app'
      'Auto-DevOps.gitlab-ci.yml'                     | :repository_source  | 'p_ci_templates_auto_devops'
      'AWS/CF-Provision-and-Deploy-EC2.gitlab-ci.yml' | :repository_source  | 'p_ci_templates_aws_cf_deploy_ec2'
      'AWS/Deploy-ECS.gitlab-ci.yml'                  | :repository_source  | 'p_ci_templates_aws_deploy_ecs'
      'Jobs/Build.gitlab-ci.yml'                      | :repository_source  | 'p_ci_templates_auto_devops_build'
      'Jobs/Deploy.gitlab-ci.yml'                     | :repository_source  | 'p_ci_templates_auto_devops_deploy'
      'Jobs/Deploy.latest.gitlab-ci.yml'              | :repository_source  | 'p_ci_templates_auto_devops_deploy_latest'
      'Security/SAST.gitlab-ci.yml'                   | :repository_source  | 'p_ci_templates_security_sast'
      'Security/Secret-Detection.gitlab-ci.yml'       | :repository_source  | 'p_ci_templates_security_secret_detection'
      'Terraform/Base.latest.gitlab-ci.yml'           | :repository_source  | 'p_ci_templates_terraform_base_latest'
    end

    with_them do
      it_behaves_like 'tracking unique hll events' do
        subject(:request) { described_class.track_unique_project_event(project_id: project_id, template: template, config_source: config_source) }

        let(:project_id) { 1 }
        let(:target_id) { expected_event }
        let(:expected_type) { instance_of(Integer) }
      end
    end

    context 'known_events coverage tests' do
      let(:project_id) { 1 }
      let(:config_source) { :repository_source }

      # These tests help guard against missing "explicit" events in known_events/ci_templates.yml
      context 'explicit include:template events' do
        described_class::TEMPLATE_TO_EVENT.keys.each do |template|
          it "does not raise error for #{template}" do
            expect do
              described_class.track_unique_project_event(project_id: project_id, template: template, config_source: config_source)
            end.not_to raise_error
          end
        end
      end

      # This test is to help guard against missing "implicit" events in known_events/ci_templates.yml
      it 'does not raise error for any template in an implicit Auto DevOps pipeline' do
        project = create(:project, :auto_devops)
        pipeline = double(project: project)
        command = double
        result = Gitlab::Ci::YamlProcessor.new(
          Gitlab::Ci::Pipeline::Chain::Config::Content::AutoDevops.new(pipeline, command).content,
          project: project,
          user: double,
          sha: double
        ).execute

        config_source = :auto_devops_source

        result.included_templates.each do |template|
          expect do
            described_class.track_unique_project_event(project_id: project.id, template: template, config_source: config_source)
          end.not_to raise_error
        end
      end
    end

    context 'templates outside of TEMPLATE_TO_EVENT' do
      let(:project_id) { 1 }
      let(:config_source) { :repository_source }

      Dir.glob(File.join('lib', 'gitlab', 'ci', 'templates', '**'), base: Rails.root) do |template|
        next if described_class::TEMPLATE_TO_EVENT.key?(template)

        it "does not track #{template}" do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to(receive(:track_event))

          described_class.track_unique_project_event(project_id: project_id, template: template, config_source: config_source)
        end
      end
    end
  end
end
