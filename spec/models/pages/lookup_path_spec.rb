# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::LookupPath, feature_category: :pages do
  let(:project) { create(:project, :pages_private, pages_https_only: true) }
  let(:trim_prefix) { nil }
  let(:domain) { nil }

  subject(:lookup_path) { described_class.new(project, trim_prefix: trim_prefix, domain: domain) }

  before do
    stub_pages_setting(
      access_control: true,
      external_https: ["1.1.1.1:443"],
      url: 'http://example.com',
      protocol: 'http'
    )
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

  describe '#https_only' do
    context 'when no domain provided' do
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
    let(:source) { lookup_path.source }

    it 'returns nil' do
      expect(source).to eq(nil)
    end

    context 'when there is pages deployment' do
      let!(:deployment) { create(:pages_deployment, project: project) }

      it 'uses deployment from object storage' do
        freeze_time do
          expect(source).to eq(
            type: 'zip',
            path: deployment.file.url(expire_at: 1.day.from_now),
            global_id: "gid://gitlab/PagesDeployment/#{deployment.id}",
            sha256: deployment.file_sha256,
            file_size: deployment.size,
            file_count: deployment.file_count
          )
        end
      end

      context 'when deployment is in the local storage' do
        before do
          deployment.file.migrate!(::ObjectStorage::Store::LOCAL)
        end

        it 'uses file protocol' do
          freeze_time do
            expect(source).to eq(
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
    end
  end

  describe '#prefix' do
    let(:trim_prefix) { 'mygroup' }

    context 'when pages group root projects' do
      let(:project) { instance_double(Project, full_path: "namespace/namespace.example.com") }

      it 'returns "/"' do
        expect(lookup_path.prefix).to eq('/')
      end
    end

    context 'when pages in the given prefix' do
      let(:project) { instance_double(Project, full_path: 'mygroup/myproject') }

      it 'returns the project full path with the provided prefix removed' do
        expect(lookup_path.prefix).to eq('/myproject/')
      end
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

    context 'when unique domain is enabled' do
      it 'returns the project unique domain' do
        project.project_setting.pages_unique_domain_enabled = true
        project.project_setting.pages_unique_domain = 'unique-domain'

        expect(lookup_path.unique_host).to eq('unique-domain.example.com')
      end

      context 'when there is domain provided' do
        let(:domain) { instance_double(PagesDomain) }

        it 'returns nil' do
          expect(lookup_path.unique_host).to eq(nil)
        end
      end
    end
  end

  describe '#root_directory' do
    context 'when there is no deployment' do
      it 'returns nil' do
        expect(lookup_path.root_directory).to be_nil
      end
    end

    context 'when there is a deployment' do
      let!(:deployment) { create(:pages_deployment, project: project, root_directory: 'foo') }

      it 'returns the deployment\'s root_directory' do
        expect(lookup_path.root_directory).to eq('foo')
      end
    end
  end
end
