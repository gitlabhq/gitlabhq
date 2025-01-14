# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::LookupPath, feature_category: :pages do
  let(:trim_prefix) { nil }
  let(:path_prefix) { nil }
  let(:file_store) { ::ObjectStorage::Store::REMOTE }
  let(:group) { build(:group, path: 'mygroup') }
  let(:deployment) do
    build(
      :pages_deployment,
      id: 1,
      project: project,
      path_prefix: path_prefix,
      file_store: file_store)
  end

  let(:project) do
    build(
      :project,
      :pages_private,
      group: group,
      path: 'myproject',
      pages_https_only: true)
  end

  subject(:lookup_path) { described_class.new(deployment: deployment, trim_prefix: trim_prefix) }

  before do
    stub_pages_setting(
      enabled: true,
      access_control: true,
      external_https: ["1.1.1.1:443"],
      url: 'http://example.com',
      protocol: 'http')

    stub_pages_object_storage(::Pages::DeploymentUploader)
  end

  describe '#project_id' do
    it 'delegates to Project#id' do
      expect(lookup_path.project_id).to eq(project.id)
    end
  end

  describe '#access_control' do
    it 'delegates to Project#private_pages?' do
      expect(lookup_path.access_control).to eq(true)
    end
  end

  describe '#primary_domain' do
    it 'delegates to Project#project_setting#pages_primary_domain' do
      project.project_setting.pages_primary_domain = 'my.domain.com'

      expect(lookup_path.primary_domain).to eq('my.domain.com')
    end
  end

  describe '#https_only' do
    subject(:lookup_path) { described_class.new(deployment: deployment, domain: domain) }

    context 'when no domain provided' do
      let(:domain) { nil }

      it 'delegates to Project#pages_https_only?' do
        expect(lookup_path.https_only).to eq(true)
      end
    end

    context 'when there is domain provided' do
      let(:domain) { instance_double(PagesDomain, https?: false) }

      it 'takes into account the https setting of the domain' do
        expect(lookup_path.https_only).to eq(false)
      end
    end
  end

  describe '#source' do
    it 'uses deployment from object storage', :freeze_time do
      expect(lookup_path.source).to eq(
        type: 'zip',
        path: deployment.file.url(expire_at: 1.day.from_now),
        global_id: "gid://gitlab/PagesDeployment/#{deployment.id}",
        sha256: deployment.file_sha256,
        file_size: deployment.size,
        file_count: deployment.file_count
      )
    end

    it 'does not recreate source hash' do
      expect(deployment.file).to receive(:url_or_file_path).once

      2.times { lookup_path.source }
    end

    context 'when deployment is in the local storage' do
      let(:file_store) { ::ObjectStorage::Store::LOCAL }

      it 'uses file protocol', :freeze_time do
        expect(lookup_path.source).to eq(
          type: 'zip',
          path: "file://#{deployment.file.path}",
          global_id: "gid://gitlab/PagesDeployment/#{deployment.id}",
          sha256: deployment.file_sha256,
          file_size: deployment.size,
          file_count: deployment.file_count
        )
      end
    end
  end

  describe '#prefix' do
    using RSpec::Parameterized::TableSyntax

    where(:full_path, :trim_prefix, :path_prefix, :result) do
      'mygroup/myproject' | nil | nil | '/'
      'mygroup/myproject' | 'mygroup' | nil | '/myproject/'
      'mygroup/myproject' | nil | 'PREFIX' | '/PREFIX/'
      'mygroup/myproject' | 'mygroup' | 'PREFIX' | '/myproject/PREFIX/'
    end

    with_them do
      before do
        allow(project).to receive(:full_path).and_return(full_path)
      end

      it { expect(lookup_path.prefix).to eq(result) }
    end
  end

  describe '#unique_host' do
    let(:project) { build(:project) }

    context 'when unique domain is disabled' do
      it 'returns nil' do
        project.project_setting.pages_unique_domain_enabled = false

        expect(lookup_path.unique_host).to be_nil
      end
    end

    context 'when namespace_in_path is enabled' do
      before do
        stub_pages_setting(namespace_in_path: true)
      end

      it 'returns nil' do
        expect(lookup_path.unique_host).to be_nil
      end
    end

    context 'when unique domain is enabled' do
      it 'returns the project unique domain' do
        project.project_setting.pages_unique_domain_enabled = true
        project.project_setting.pages_unique_domain = 'unique-domain'

        expect(lookup_path.unique_host).to eq('unique-domain.example.com')
      end
    end
  end

  describe '#root_directory' do
    context 'when there is a deployment' do
      let(:deployment) { build_stubbed(:pages_deployment, project: project, root_directory: 'foo') }

      it 'returns the deployment\'s root_directory' do
        expect(lookup_path.root_directory).to eq('foo')
      end
    end
  end
end
