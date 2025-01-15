# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SastBuildAction do
  let(:default_sast_values) do
    { global:
      [
        { field: 'SECURE_ANALYZERS_PREFIX', default_value: 'registry.gitlab.com/security-products', value: 'registry.gitlab.com/security-products' }
      ],
      pipeline:
      [
        { field: 'stage', default_value: 'test', value: 'test' },
        { field: 'SEARCH_MAX_DEPTH', default_value: 4, value: 4 },
        { field: 'SAST_EXCLUDED_PATHS', default_value: 'spec, test, tests, tmp', value: 'spec, test, tests, tmp' }
      ] }
  end

  let(:params) do
    { global:
      [
        { field: 'SECURE_ANALYZERS_PREFIX', default_value: 'registry.gitlab.com/security-products', value: 'new_registry' }
      ],
      pipeline:
      [
        { field: 'stage', default_value: 'test', value: 'security' },
        { field: 'SEARCH_MAX_DEPTH', default_value: 4, value: 1 },
        { field: 'SAST_EXCLUDED_PATHS', default_value: 'spec, test, tests, tmp', value: 'spec,docs' }
      ] }
  end

  let(:params_with_analyzer_info) do
    params.merge({
      analyzers: [
        {
          name: "bandit",
          enabled: false
        },
        {
          name: "brakeman",
          enabled: true,
          variables: [
            { field: "SAST_BRAKEMAN_LEVEL", default_value: "1", value: "2" }
          ]
        },
        {
          name: "flawfinder",
          enabled: true,
          variables: [
            { field: "SAST_FLAWFINDER_LEVEL", default_value: "1", value: "1" }
          ]
        }
      ]
    })
  end

  let(:params_with_all_analyzers_enabled) do
    params.merge({
      analyzers: [
        {
          name: "flawfinder",
          enabled: true
        },
        {
          name: "brakeman",
          enabled: true
        }
      ]
    })
  end

  context 'with existing .gitlab-ci.yml' do
    let(:auto_devops_enabled) { false }

    context 'sast has not been included' do
      context 'template includes are array' do
        let(:gitlab_ci_content) { existing_gitlab_ci_and_template_array_without_sast }

        subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

        it 'generates the correct YML' do
          expect(result[:action]).to eq('update')
          expect(result[:content]).to eq(sast_yaml_two_includes)
        end
      end

      context 'template include is not an array' do
        let(:gitlab_ci_content) { existing_gitlab_ci_and_single_template_without_sast }

        subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

        it 'generates the correct YML' do
          expect(result[:action]).to eq('update')
          expect(result[:content]).to eq(sast_yaml_two_includes)
        end

        it 'reports defaults have been overwritten' do
          expect(result[:default_values_overwritten]).to eq(true)
        end
      end
    end

    context 'sast template include is not an array' do
      let(:gitlab_ci_content) { existing_gitlab_ci_and_single_template_with_sast_and_default_stage }

      subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

      it 'generates the correct YML' do
        expect(result[:action]).to eq('update')
        expect(result[:content]).to eq(sast_yaml_all_params)
      end
    end

    context 'with default values' do
      let(:params) { default_sast_values }
      let(:gitlab_ci_content) { existing_gitlab_ci_and_single_template_with_sast_and_default_stage }

      subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

      it 'generates the correct YML' do
        expect(result[:content]).to eq(sast_yaml_with_no_variables_set)
      end

      it 'reports defaults have not been overwritten' do
        expect(result[:default_values_overwritten]).to eq(false)
      end

      context 'analyzer section' do
        let(:gitlab_ci_content) { existing_gitlab_ci_and_single_template_with_sast_and_default_stage }

        subject(:result) { described_class.new(auto_devops_enabled, params_with_analyzer_info, gitlab_ci_content).generate }

        it 'generates the correct YML' do
          expect(result[:content]).to eq(sast_yaml_with_no_variables_set_but_analyzers)
        end

        context 'analyzers are disabled' do
          let(:gitlab_ci_content) { existing_gitlab_ci_and_single_template_with_sast_and_default_stage }

          subject(:result) { described_class.new(auto_devops_enabled, params_with_analyzer_info, gitlab_ci_content).generate }

          it 'writes SAST_EXCLUDED_ANALYZERS' do
            expect(result[:content]).to eq(sast_yaml_with_no_variables_set_but_analyzers)
          end
        end

        context 'all analyzers are enabled' do
          let(:gitlab_ci_content) { existing_gitlab_ci_and_single_template_with_sast_and_default_stage }

          subject(:result) { described_class.new(auto_devops_enabled, params_with_all_analyzers_enabled, gitlab_ci_content).generate }

          it 'does not write SAST_EXCLUDED_ANALYZERS' do
            expect(result[:content]).to eq(sast_yaml_with_no_variables_set)
          end
        end
      end
    end

    context 'with update stage and SEARCH_MAX_DEPTH and set SECURE_ANALYZERS_PREFIX to default' do
      let(:params) do
        { global:
          [
            { field: 'SECURE_ANALYZERS_PREFIX', default_value: 'registry.gitlab.com/security-products', value: 'registry.gitlab.com/security-products' }
          ],
          pipeline:
          [
            { field: 'stage', default_value: 'test', value: 'brand_new_stage' },
            { field: 'SEARCH_MAX_DEPTH', default_value: 4, value: 5 },
            { field: 'SAST_EXCLUDED_PATHS', default_value: 'spec, test, tests, tmp', value: 'spec,docs' }
          ] }
      end

      let(:gitlab_ci_content) { existing_gitlab_ci }

      subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

      it 'generates the correct YML' do
        expect(result[:action]).to eq('update')
        expect(result[:content]).to eq(sast_yaml_updated_stage)
      end
    end

    context 'with no existing variables' do
      let(:gitlab_ci_content) { existing_gitlab_ci_with_no_variables }

      subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

      it 'generates the correct YML' do
        expect(result[:action]).to eq('update')
        expect(result[:content]).to eq(sast_yaml_variable_section_added)
      end
    end

    context 'with no existing sast config' do
      let(:gitlab_ci_content) { existing_gitlab_ci_with_no_sast_section }

      subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

      it 'generates the correct YML' do
        expect(result[:action]).to eq('update')
        expect(result[:content]).to eq(sast_yaml_sast_section_added)
      end
    end

    context 'with no existing sast variables' do
      let(:gitlab_ci_content) { existing_gitlab_ci_with_no_sast_variables }

      subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

      it 'generates the correct YML' do
        expect(result[:action]).to eq('update')
        expect(result[:content]).to eq(sast_yaml_sast_variables_section_added)
      end
    end

    def existing_gitlab_ci_and_template_array_without_sast
      { "stages" => %w[test security],
        "variables" => { "RANDOM" => "make sure this persists", "SECURE_ANALYZERS_PREFIX" => "localhost:5000/analyzers" },
        "sast" => { "variables" => { "SEARCH_MAX_DEPTH" => 1 }, "stage" => "security" },
        "include" => [{ "template" => "existing.yml" }] }
    end

    def existing_gitlab_ci_and_single_template_with_sast_and_default_stage
      { "stages" => %w[test],
        "variables" => { "SECURE_ANALYZERS_PREFIX" => "localhost:5000/analyzers" },
        "sast" => { "variables" => { "SEARCH_MAX_DEPTH" => 1 }, "stage" => "test" },
        "include" => { "template" => "Security/SAST.gitlab-ci.yml" } }
    end

    def existing_gitlab_ci_and_single_template_without_sast
      { "stages" => %w[test security],
        "variables" => { "RANDOM" => "make sure this persists", "SECURE_ANALYZERS_PREFIX" => "localhost:5000/analyzers" },
        "sast" => { "variables" => { "SEARCH_MAX_DEPTH" => 1 }, "stage" => "security" },
        "include" => { "template" => "existing.yml" } }
    end

    def existing_gitlab_ci_with_no_variables
      { "stages" => %w[test security],
        "sast" => { "variables" => { "SEARCH_MAX_DEPTH" => 1 }, "stage" => "security" },
        "include" => [{ "template" => "Security/SAST.gitlab-ci.yml" }] }
    end

    def existing_gitlab_ci_with_no_sast_section
      { "stages" => %w[test security],
        "variables" => { "RANDOM" => "make sure this persists", "SECURE_ANALYZERS_PREFIX" => "localhost:5000/analyzers" },
        "include" => [{ "template" => "Security/SAST.gitlab-ci.yml" }] }
    end

    def existing_gitlab_ci_with_no_sast_variables
      { "stages" => %w[test security],
        "variables" => { "RANDOM" => "make sure this persists", "SECURE_ANALYZERS_PREFIX" => "localhost:5000/analyzers" },
        "sast" => { "stage" => "security" },
        "include" => [{ "template" => "Security/SAST.gitlab-ci.yml" }] }
    end

    def existing_gitlab_ci
      { "stages" => %w[test security],
        "variables" => { "RANDOM" => "make sure this persists", "SECURE_ANALYZERS_PREFIX" => "bad_prefix" },
        "sast" => { "variables" => { "SEARCH_MAX_DEPTH" => 1 }, "stage" => "security" },
        "include" => [{ "template" => "Security/SAST.gitlab-ci.yml" }] }
    end
  end

  context 'with no .gitlab-ci.yml' do
    let(:gitlab_ci_content) { nil }

    context 'autodevops disabled' do
      let(:auto_devops_enabled) { false }

      context 'with one empty parameter' do
        let(:params) do
          { global:
            [
              { field: 'SECURE_ANALYZERS_PREFIX', default_value: 'registry.gitlab.com/security-products', value: '' }
            ] }
        end

        subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

        it 'generates the correct YML' do
          expect(result[:content]).to eq(sast_yaml_with_no_variables_set)
        end
      end

      context 'with all parameters' do
        subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

        it 'generates the correct YML' do
          expect(result[:content]).to eq(sast_yaml_all_params)
        end
      end
    end

    context 'with autodevops enabled' do
      let(:auto_devops_enabled) { true }

      subject(:result) { described_class.new(auto_devops_enabled, params, gitlab_ci_content).generate }

      before do
        allow_next_instance_of(described_class) do |sast_build_action|
          allow(sast_build_action).to receive(:auto_devops_stages).and_return(fast_auto_devops_stages)
        end
      end

      it 'generates the correct YML' do
        expect(result[:content]).to eq(auto_devops_with_custom_stage)
      end
    end
  end

  # stubbing this method allows this spec file to use fast_spec_helper
  def fast_auto_devops_stages
    auto_devops_template = YAML.safe_load(File.read('lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml'))
    auto_devops_template['stages']
  end

  def sast_yaml_with_no_variables_set_but_analyzers
    <<-CI_YML.strip_heredoc
    # You can override the included template(s) by including variable overrides
    # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
    # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/pipeline/#customization
    # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
    # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
    # Note that environment variables can be set in several places
    # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
    stages:
    - test
    sast:
      variables:
        SAST_EXCLUDED_ANALYZERS: bandit
        SAST_BRAKEMAN_LEVEL: '2'
      stage: test
    include:
    - template: Security/SAST.gitlab-ci.yml
    CI_YML
  end

  def sast_yaml_with_no_variables_set
    <<-CI_YML.strip_heredoc
    # You can override the included template(s) by including variable overrides
    # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
    # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/pipeline/#customization
    # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
    # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
    # Note that environment variables can be set in several places
    # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
    stages:
    - test
    sast:
      stage: test
    include:
    - template: Security/SAST.gitlab-ci.yml
    CI_YML
  end

  def sast_yaml_all_params
    <<-CI_YML.strip_heredoc
      # You can override the included template(s) by including variable overrides
      # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
      # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/pipeline/#customization
      # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
      # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
      # Note that environment variables can be set in several places
      # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
      stages:
      - test
      - security
      variables:
        SECURE_ANALYZERS_PREFIX: new_registry
      sast:
        variables:
          SAST_EXCLUDED_PATHS: spec,docs
          SEARCH_MAX_DEPTH: 1
        stage: security
      include:
      - template: Security/SAST.gitlab-ci.yml
    CI_YML
  end

  def auto_devops_with_custom_stage
    <<-CI_YML.strip_heredoc
      # You can override the included template(s) by including variable overrides
      # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
      # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/pipeline/#customization
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
      - security
      variables:
        SECURE_ANALYZERS_PREFIX: new_registry
      sast:
        variables:
          SAST_EXCLUDED_PATHS: spec,docs
          SEARCH_MAX_DEPTH: 1
        stage: security
      include:
      - template: Auto-DevOps.gitlab-ci.yml
    CI_YML
  end

  def sast_yaml_two_includes
    <<-CI_YML.strip_heredoc
      # You can override the included template(s) by including variable overrides
      # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
      # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/pipeline/#customization
      # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
      # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
      # Note that environment variables can be set in several places
      # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
      stages:
      - test
      - security
      variables:
        RANDOM: make sure this persists
        SECURE_ANALYZERS_PREFIX: new_registry
      sast:
        variables:
          SAST_EXCLUDED_PATHS: spec,docs
          SEARCH_MAX_DEPTH: 1
        stage: security
      include:
      - template: existing.yml
      - template: Security/SAST.gitlab-ci.yml
    CI_YML
  end

  def sast_yaml_variable_section_added
    <<-CI_YML.strip_heredoc
      # You can override the included template(s) by including variable overrides
      # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
      # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/pipeline/#customization
      # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
      # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
      # Note that environment variables can be set in several places
      # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
      stages:
      - test
      - security
      sast:
        variables:
          SAST_EXCLUDED_PATHS: spec,docs
          SEARCH_MAX_DEPTH: 1
        stage: security
      include:
      - template: Security/SAST.gitlab-ci.yml
      variables:
        SECURE_ANALYZERS_PREFIX: new_registry
    CI_YML
  end

  def sast_yaml_sast_section_added
    <<-CI_YML.strip_heredoc
      # You can override the included template(s) by including variable overrides
      # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
      # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/pipeline/#customization
      # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
      # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
      # Note that environment variables can be set in several places
      # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
      stages:
      - test
      - security
      variables:
        RANDOM: make sure this persists
        SECURE_ANALYZERS_PREFIX: new_registry
      include:
      - template: Security/SAST.gitlab-ci.yml
      sast:
        variables:
          SAST_EXCLUDED_PATHS: spec,docs
          SEARCH_MAX_DEPTH: 1
        stage: security
    CI_YML
  end

  def sast_yaml_sast_variables_section_added
    <<-CI_YML.strip_heredoc
      # You can override the included template(s) by including variable overrides
      # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
      # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/pipeline/#customization
      # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
      # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
      # Note that environment variables can be set in several places
      # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
      stages:
      - test
      - security
      variables:
        RANDOM: make sure this persists
        SECURE_ANALYZERS_PREFIX: new_registry
      sast:
        stage: security
        variables:
          SAST_EXCLUDED_PATHS: spec,docs
          SEARCH_MAX_DEPTH: 1
      include:
      - template: Security/SAST.gitlab-ci.yml
    CI_YML
  end

  def sast_yaml_updated_stage
    <<-CI_YML.strip_heredoc
      # You can override the included template(s) by including variable overrides
      # SAST customization: https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
      # Secret Detection customization: https://docs.gitlab.com/ee/user/application_security/secret_detection/pipeline/#customization
      # Dependency Scanning customization: https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#customizing-the-dependency-scanning-settings
      # Container Scanning customization: https://docs.gitlab.com/ee/user/application_security/container_scanning/#customizing-the-container-scanning-settings
      # Note that environment variables can be set in several places
      # See https://docs.gitlab.com/ee/ci/variables/#cicd-variable-precedence
      stages:
      - test
      - security
      - brand_new_stage
      variables:
        RANDOM: make sure this persists
      sast:
        variables:
          SAST_EXCLUDED_PATHS: spec,docs
          SEARCH_MAX_DEPTH: 5
        stage: brand_new_stage
      include:
      - template: Security/SAST.gitlab-ci.yml
    CI_YML
  end
end
