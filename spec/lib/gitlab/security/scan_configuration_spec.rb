# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Security::ScanConfiguration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }

  let(:scan) { described_class.new(project: project, type: type, configured: configured) }

  describe '#available?' do
    subject { scan.available? }

    let(:configured) { true }

    context 'with a core scanner' do
      where(type: %i[sast sast_iac secret_detection container_scanning])

      with_them do
        it { is_expected.to be_truthy }
      end
    end

    context 'with custom scanner' do
      let(:type) { :my_scanner }

      it { is_expected.to be_falsey }
    end
  end

  describe '#configured?' do
    subject { scan.configured? }

    let(:type) { :sast }
    let(:configured) { false }

    it { is_expected.to be_falsey }
  end

  describe '#configuration_path' do
    subject { scan.configuration_path }

    let(:configured) { true }
    let(:type) { :sast }

    it { is_expected.to be_nil }
  end

  describe '#meta_info_path' do
    subject { scan.meta_info_path }

    let(:configured) { true }
    let(:available) { true }
    let(:type) { :dast }

    it { is_expected.to be_nil }
  end

  describe '#on_demand_available?' do
    subject { scan.on_demand_available? }

    let(:configured) { true }
    let(:available) { true }
    let(:type) { :sast }

    it { is_expected.to be_falsey }
  end

  describe '#can_enable_by_merge_request?' do
    subject { scan.can_enable_by_merge_request? }

    let(:configured) { true }

    context 'with a core scanner' do
      where(type: %i[sast sast_iac secret_detection])

      with_them do
        it { is_expected.to be_truthy }
      end
    end

    context 'with a custom scanner' do
      let(:type) { :my_scanner }

      it { is_expected.to be_falsey }
    end
  end

  describe '#security_features' do
    subject { scan.security_features }

    using RSpec::Parameterized::TableSyntax

    where(:scan_type, :features_hash) do
      :sast | { name: "Static Application Security Testing (SAST)",
         short_name: "SAST",
         description: "Analyze your source code for vulnerabilities.",
         help_path: "/help/user/application_security/sast/_index.md",
         configuration_help_path: "/help/user/application_security/sast/_index.md#configuration",
         type: "sast" }
      :sast_iac | { name: "Infrastructure as Code (IaC) Scanning",
        short_name: "SAST IaC",
        description: "Analyze your infrastructure as code configuration files for known vulnerabilities.",
        help_path: "/help/user/application_security/iac_scanning/_index.md",
        configuration_help_path: "/help/user/application_security/iac_scanning/_index.md#configuration",
        type: "sast_iac" }
      :dast | {
        badge: { text: "Available on demand",
                 tooltip_text: "On-demand scans run outside of the DevOps " \
                               "cycle and find vulnerabilities in your projects",
                 variant: "neutral" },
        secondary: {
          type: "dast_profiles",
          name: "DAST profiles",
          description: "Manage profiles for use by DAST scans.",
          configuration_text: "Manage profiles"
        },
        name: "Dynamic Application Security Testing (DAST)",
        short_name: "DAST",
        description: "Analyze a deployed version of your web application for known " \
                     "vulnerabilities by examining it from the outside in. DAST works by simulating " \
                     "external attacks on your application while it is running.",
        help_path: "/help/user/application_security/dast/_index.md",
        configuration_help_path: "/help/user/application_security/dast/_index.md#enable-automatic-dast-run",
        type: "dast",
        anchor: "dast"
      }
      :dependency_scanning | { name: "Dependency Scanning",
        description: "Analyze your dependencies for known vulnerabilities.",
        help_path: "/help/user/application_security/dependency_scanning/_index.md",
        configuration_help_path: "/help/user/application_security/dependency_scanning/_index.md#configuration",
        type: "dependency_scanning",
        anchor: "dependency-scanning" }
      :container_scanning | { name: "Container Scanning",
        description: "Check your Docker images for known vulnerabilities.",
        help_path: "/help/user/application_security/container_scanning/_index.md",
        configuration_help_path: "/help/user/application_security/container_scanning/_index.md#configuration",
        type: "container_scanning" }
      :secret_push_protection | { name: _("Secret push protection"),
        description: "Block secrets such as keys and API tokens from being pushed to your repositories. " \
                     "Secret push protection is triggered when commits are pushed to a repository. " \
                     "If any secrets are detected, the push is blocked.",
        help_path: Gitlab::Routing.url_helpers.help_page_path(
          "user/application_security/secret_detection/secret_push_protection/_index.md"),
        type: "secret_push_protection" }
      :secret_detection | { name: "Pipeline Secret Detection",
        description: "Analyze your source code and Git history for secrets by using CI/CD pipelines.",
        help_path: "/help/user/application_security/secret_detection/pipeline/_index.md",
        configuration_help_path: "/help/user/application_security/secret_detection/pipeline/_index.md#configuration",
        type: "secret_detection" }
      :api_fuzzing | { name: "API Fuzzing",
        description: "Find bugs in your code with API fuzzing.",
        help_path: "/help/user/application_security/api_fuzzing/_index.md",
        type: "api_fuzzing" }
      :coverage_fuzzing | { name: "Coverage Fuzzing",
        description: "Find bugs in your code with coverage-guided fuzzing.",
        help_path: "/help/user/application_security/coverage_fuzzing/_index.md",
        configuration_help_path: \
          "/help/user/application_security/coverage_fuzzing/_index.md#enable-coverage-guided-fuzz-testing",
        type: "coverage_fuzzing",
        secondary: { type: "corpus_management",
                     name: "Corpus Management",
                     description: "Manage corpus files used as " \
                                  "seed inputs with coverage-guided fuzzing.",
                     configuration_text: "Manage corpus" } }
      :invalid | {}
    end

    with_them do
      let(:type) { scan_type }
      let(:configured) { true }

      it { is_expected.to eq features_hash }
    end
  end
end
