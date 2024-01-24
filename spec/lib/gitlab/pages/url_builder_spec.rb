# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::UrlBuilder, feature_category: :pages do
  let(:pages_enabled) { true }
  let(:artifacts_server) { true }
  let(:access_control) { true }

  let(:port) { nil }
  let(:host) { 'example.com' }

  let(:full_path) { 'group/project' }
  let(:project_public) { true }
  let(:unique_domain) { 'unique-domain' }
  let(:unique_domain_enabled) { false }
  let(:namespace_in_path) { false }

  let(:project_setting) do
    instance_double(
      ProjectSetting,
      pages_unique_domain: unique_domain,
      pages_unique_domain_enabled?: unique_domain_enabled
    )
  end

  let(:project) do
    instance_double(
      Project,
      flipper_id: 'project:1', # required for the feature flag check
      public?: project_public,
      project_setting: project_setting,
      full_path: full_path
    )
  end

  subject(:builder) { described_class.new(project) }

  before do
    stub_pages_setting(
      enabled: pages_enabled,
      host: host,
      url: 'http://example.com',
      protocol: 'http',
      artifacts_server: artifacts_server,
      access_control: access_control,
      port: port,
      namespace_in_path: namespace_in_path
    )
  end

  describe '#pages_url' do
    subject(:pages_url) { builder.pages_url }

    it { is_expected.to eq('http://group.example.com/project') }

    context 'when namespace_in_path is false' do
      let(:namespace_in_path) { false }

      context 'when namespace is upper cased' do
        let(:full_path) { 'Group/project' }

        it { is_expected.to eq('http://group.example.com/project') }
      end

      context 'when project is in a nested group page' do
        let(:full_path) { 'group/subgroup/project' }

        it { is_expected.to eq('http://group.example.com/subgroup/project') }
      end

      context 'when using domain pages' do
        let(:full_path) { 'group/group.example.com' }

        it { is_expected.to eq('http://group.example.com') }

        context 'in development mode' do
          let(:port) { 3010 }

          before do
            stub_rails_env('development')
          end

          it { is_expected.to eq('http://group.example.com:3010') }
        end
      end

      context 'when not using pages_unique_domain' do
        subject(:pages_url) { builder.pages_url(with_unique_domain: false) }

        context 'when pages_unique_domain_enabled is false' do
          let(:unique_domain_enabled) { false }

          it { is_expected.to eq('http://group.example.com/project') }
        end

        context 'when pages_unique_domain_enabled is true' do
          let(:unique_domain_enabled) { true }

          it { is_expected.to eq('http://group.example.com/project') }
        end
      end

      context 'when using pages_unique_domain' do
        subject(:pages_url) { builder.pages_url(with_unique_domain: true) }

        context 'when pages_unique_domain_enabled is false' do
          let(:unique_domain_enabled) { false }

          it { is_expected.to eq('http://group.example.com/project') }
        end

        context 'when pages_unique_domain_enabled is true' do
          let(:unique_domain_enabled) { true }

          it { is_expected.to eq('http://unique-domain.example.com') }
        end
      end
    end

    context 'when namespace_in_path is true' do
      let(:namespace_in_path) { true }

      context 'when namespace is upper cased' do
        let(:full_path) { 'Group/project' }

        it { is_expected.to eq('http://example.com/group/project') }
      end

      context 'when project is in a nested group page' do
        let(:full_path) { 'group/subgroup/project' }

        it { is_expected.to eq('http://example.com/group/subgroup/project') }
      end

      context 'when using domain pages' do
        let(:full_path) { 'group/group.example.com' }

        it { is_expected.to eq('http://example.com/group/group.example.com') }

        context 'in development mode' do
          let(:port) { 3010 }

          before do
            stub_rails_env('development')
          end

          it { is_expected.to eq('http://example.com:3010/group/group.example.com') }
        end
      end

      context 'when not using pages_unique_domain' do
        subject(:pages_url) { builder.pages_url(with_unique_domain: false) }

        context 'when pages_unique_domain_enabled is false' do
          let(:unique_domain_enabled) { false }

          it { is_expected.to eq('http://example.com/group/project') }
        end

        context 'when pages_unique_domain_enabled is true' do
          let(:unique_domain_enabled) { true }

          it { is_expected.to eq('http://example.com/group/project') }
        end
      end

      context 'when using pages_unique_domain' do
        subject(:pages_url) { builder.pages_url(with_unique_domain: true) }

        context 'when pages_unique_domain_enabled is false' do
          let(:unique_domain_enabled) { false }

          it { is_expected.to eq('http://example.com/group/project') }
        end

        context 'when pages_unique_domain_enabled is true' do
          let(:unique_domain_enabled) { true }

          it { is_expected.to eq('http://example.com/unique-domain') }
        end
      end
    end
  end

  describe '#unique_host' do
    subject(:unique_host) { builder.unique_host }

    context 'when pages_unique_domain_enabled is false' do
      let(:unique_domain_enabled) { false }

      it { is_expected.to be_nil }
    end

    context 'when namespace_in_path is true' do
      let(:namespace_in_path) { true }

      it { is_expected.to be_nil }
    end

    context 'when pages_unique_domain_enabled is true' do
      let(:unique_domain_enabled) { true }

      it { is_expected.to eq('unique-domain.example.com') }
    end
  end

  describe '#artifact_url' do
    let(:job) { instance_double(Ci::Build, id: 1) }
    let(:artifact) do
      instance_double(
        Gitlab::Ci::Build::Artifacts::Metadata::Entry,
        name: artifact_name,
        path: "path/#{artifact_name}")
    end

    subject(:artifact_url) { builder.artifact_url(artifact, job) }

    context 'with not allowed extension' do
      let(:artifact_name) { 'file.gif' }

      it { is_expected.to be_nil }
    end

    context 'with allowed extension' do
      let(:artifact_name) { 'file.txt' }

      it { is_expected.to eq("http://group.example.com/-/project/-/jobs/1/artifacts/path/file.txt") }

      context 'when port is configured' do
        let(:port) { 1234 }

        it { is_expected.to eq("http://group.example.com:1234/-/project/-/jobs/1/artifacts/path/file.txt") }
      end
    end

    context 'with namespace_in_path enabled and allowed extension' do
      let(:artifact_name) { 'file.txt' }
      let(:namespace_in_path) { true }

      it { is_expected.to eq("http://example.com/group/-/project/-/jobs/1/artifacts/path/file.txt") }

      context 'when port is configured' do
        let(:port) { 1234 }

        it { is_expected.to eq("http://example.com:1234/group/-/project/-/jobs/1/artifacts/path/file.txt") }
      end
    end
  end

  describe '#artifact_url_available?' do
    let(:job) { instance_double(Ci::Build, id: 1) }
    let(:artifact) do
      instance_double(
        Gitlab::Ci::Build::Artifacts::Metadata::Entry,
        name: artifact_name,
        path: "path/#{artifact_name}")
    end

    subject(:artifact_url_available) { builder.artifact_url_available?(artifact, job) }

    context 'with not allowed extensions' do
      let(:artifact_name) { 'file.gif' }

      it { is_expected.to be false }
    end

    context 'with allowed extensions' do
      let(:artifact_name) { 'file.txt' }

      it { is_expected.to be true }
    end
  end
end
