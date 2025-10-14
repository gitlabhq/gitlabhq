# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SecretDetectionBuildAction, feature_category: :secret_detection do
  subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

  let(:params) { {} }

  context 'with existing .gitlab-ci.yml' do
    let(:auto_devops_enabled) { false }

    context 'secret_detection has not been included' do
      let(:expected_yml) do
        <<-CI_YML.strip_heredoc
          # You can override the included template(s) by including variable overrides
          # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
          # Secret Detection customization: https://docs.gitlab.com/user/application_security/secret_detection/pipeline/configure
          # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
          # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
          # Note that environment variables can be set in several places
          # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
          stages:
          - test
          - security
          - secret-detection
          variables:
            RANDOM: make sure this persists
          include:
          - template: existing.yml
          - template: Security/Secret-Detection.gitlab-ci.yml
          secret_detection:
            stage: secret-detection
        CI_YML
      end

      context 'template includes are an array' do
        let(:gitlab_ci_content) do
          { "stages" => %w[test security],
            "variables" => { "RANDOM" => "make sure this persists" },
            "include" => [{ "template" => "existing.yml" }] }
        end

        it 'generates the correct YML' do
          expect(result[:action]).to eq('update')
          expect(result[:content]).to eq(expected_yml)
        end
      end

      context 'template include is not an array' do
        let(:gitlab_ci_content) do
          { "stages" => %w[test security],
            "variables" => { "RANDOM" => "make sure this persists" },
            "include" => { "template" => "existing.yml" } }
        end

        it 'generates the correct YML' do
          expect(result[:action]).to eq('update')
          expect(result[:content]).to eq(expected_yml)
        end
      end
    end

    context 'secret_detection has been included' do
      let(:expected_yml) do
        <<-CI_YML.strip_heredoc
          # You can override the included template(s) by including variable overrides
          # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
          # Secret Detection customization: https://docs.gitlab.com/user/application_security/secret_detection/pipeline/configure
          # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
          # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
          # Note that environment variables can be set in several places
          # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
          stages:
          - test
          - secret-detection
          variables:
            RANDOM: make sure this persists
          include:
          - template: Security/Secret-Detection.gitlab-ci.yml
          secret_detection:
            stage: secret-detection
        CI_YML
      end

      context 'secret_detection template include are an array' do
        let(:gitlab_ci_content) do
          { "stages" => %w[test],
            "variables" => { "RANDOM" => "make sure this persists" },
            "include" => [{ "template" => "Security/Secret-Detection.gitlab-ci.yml" }] }
        end

        it 'generates the correct YML' do
          expect(result[:action]).to eq('update')
          expect(result[:content]).to eq(expected_yml)
        end
      end

      context 'secret_detection template contains symbolized keys' do
        let(:gitlab_ci_content) do
          { stages: %w[test],
            variables: { "RANDOM" => "make sure this persists" },
            include: [{ "template" => "Security/Secret-Detection.gitlab-ci.yml" }] }
        end

        it 'generates the correct YML' do
          expect(result[:action]).to eq('update')
          expect(result[:content]).to eq(expected_yml)
        end
      end

      context 'secret_detection template include is not an array' do
        let(:gitlab_ci_content) do
          { "stages" => %w[test],
            "variables" => { "RANDOM" => "make sure this persists" },
            "include" => { "template" => "Security/Secret-Detection.gitlab-ci.yml" } }
        end

        it 'generates the correct YML' do
          expect(result[:action]).to eq('update')
          expect(result[:content]).to eq(expected_yml)
        end
      end
    end
  end

  context 'with no .gitlab-ci.yml' do
    let(:gitlab_ci_content) { nil }

    context 'autodevops disabled' do
      let(:auto_devops_enabled) { false }
      let(:expected_yml) do
        <<-CI_YML.strip_heredoc
          # You can override the included template(s) by including variable overrides
          # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
          # Secret Detection customization: https://docs.gitlab.com/user/application_security/secret_detection/pipeline/configure
          # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
          # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
          # Note that environment variables can be set in several places
          # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
          stages:
          - test
          - secret-detection
          secret_detection:
            stage: secret-detection
          include:
          - template: Security/Secret-Detection.gitlab-ci.yml
        CI_YML
      end

      it 'generates the correct YML' do
        expect(result[:action]).to eq('create')
        expect(result[:content]).to eq(expected_yml)
      end
    end

    context 'with autodevops enabled' do
      let(:auto_devops_enabled) { true }
      let(:expected_yml) do
        <<-CI_YML.strip_heredoc
          # You can override the included template(s) by including variable overrides
          # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
          # Secret Detection customization: https://docs.gitlab.com/user/application_security/secret_detection/pipeline/configure
          # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
          # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
          # Note that environment variables can be set in several places
          # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
          stages:
          - build
          - test
          - deploy
          - review
          - dast
          - staging
          - canary
          - production
          - incremental rollout 10%
          - incremental rollout 25%
          - incremental rollout 50%
          - incremental rollout 100%
          - performance
          - cleanup
          - secret-detection
          secret_detection:
            stage: secret-detection
          include:
          - template: Auto-DevOps.gitlab-ci.yml
        CI_YML
      end

      before do
        allow_next_instance_of(described_class) do |secret_detection_build_actions|
          allow(secret_detection_build_actions).to receive(:auto_devops_stages).and_return(fast_auto_devops_stages)
        end
      end

      it 'generates the correct YML' do
        expect(result[:action]).to eq('create')
        expect(result[:content]).to eq(expected_yml)
      end
    end
  end

  context 'with initialize_with_secret_detection param' do
    let(:auto_devops_enabled) { false }
    let(:gitlab_ci_content) { nil }
    let(:params) { { initialize_with_secret_detection: true } }

    it 'sets SECRET_DETECTION_ENABLED to true' do
      expect(result[:default_values_overwritten]).to be_truthy
    end
  end

  describe 'when sast_also_enabled is true' do
    let(:auto_devops_enabled) { false }
    let(:gitlab_ci_content) { nil }
    let(:params) { { sast_also_enabled: true } }

    it 'maintains the same behavior for secret detection' do
      expect(result[:action]).to eq('create')
      expect(result[:content]).to include('Security/Secret-Detection.gitlab-ci.yml')
    end
  end

  # stubbing this method allows this spec file to use fast_spec_helper
  def fast_auto_devops_stages
    auto_devops_template = YAML.safe_load(File.read('lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml'))
    auto_devops_template['stages']
  end

  context 'when Auto-DevOps template cannot be processed' do
    let(:auto_devops_enabled) { true }
    let(:gitlab_ci_content) { nil }
    let(:build_action) { described_class.new(auto_devops_enabled, params, gitlab_ci_content) }

    before do
      allow(Gitlab::Template::GitlabCiYmlTemplate).to receive(:find)
        .with('Auto-DevOps')
        .and_raise(StandardError.new("Template processing error"))
    end

    it 'logs the error and returns default stages' do
      expect(Gitlab::AppLogger).to receive(:error)
        .with("Failed to process Auto-DevOps template: Template processing error")

      expect(build_action.send(:auto_devops_stages)).to eq(%w[build test deploy])
    end
  end
end
