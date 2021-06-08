# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::LookupPath do
  let(:project) { create(:project, :pages_private, pages_https_only: true) }

  subject(:lookup_path) { described_class.new(project) }

  before do
    stub_pages_setting(access_control: true, external_https: ["1.1.1.1:443"])
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
    subject(:lookup_path) { described_class.new(project, domain: domain) }

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
    let(:source) { lookup_path.source }

    it 'returns nil' do
      expect(source).to eq(nil)
    end

    context 'when there is pages deployment' do
      let(:deployment) { create(:pages_deployment, project: project) }

      before do
        project.mark_pages_as_deployed
        project.pages_metadatum.update!(pages_deployment: deployment)
      end

      it 'uses deployment from object storage' do
        freeze_time do
          expect(source).to(
            eq({
                 type: 'zip',
                 path: deployment.file.url(expire_at: 1.day.from_now),
                 global_id: "gid://gitlab/PagesDeployment/#{deployment.id}",
                 sha256: deployment.file_sha256,
                 file_size: deployment.size,
                 file_count: deployment.file_count
               })
          )
        end
      end

      context 'when deployment is in the local storage' do
        before do
          deployment.file.migrate!(::ObjectStorage::Store::LOCAL)
        end

        it 'uses file protocol' do
          freeze_time do
            expect(source).to(
              eq({
                   type: 'zip',
                   path: 'file://' + deployment.file.path,
                   global_id: "gid://gitlab/PagesDeployment/#{deployment.id}",
                   sha256: deployment.file_sha256,
                   file_size: deployment.size,
                   file_count: deployment.file_count
                 })
            )
          end
        end
      end

      context 'when deployment were created during migration' do
        before do
          allow(deployment).to receive(:migrated?).and_return(true)
        end

        it 'uses deployment from object storage' do
          freeze_time do
            expect(source).to(
              eq({
                   type: 'zip',
                   path: deployment.file.url(expire_at: 1.day.from_now),
                   global_id: "gid://gitlab/PagesDeployment/#{deployment.id}",
                   sha256: deployment.file_sha256,
                   file_size: deployment.size,
                   file_count: deployment.file_count
                 })
            )
          end
        end
      end
    end
  end

  describe '#prefix' do
    it 'returns "/" for pages group root projects' do
      project = instance_double(Project, pages_group_root?: true)
      lookup_path = described_class.new(project, trim_prefix: 'mygroup')

      expect(lookup_path.prefix).to eq('/')
    end

    it 'returns the project full path with the provided prefix removed' do
      project = instance_double(Project, pages_group_root?: false, full_path: 'mygroup/myproject')
      lookup_path = described_class.new(project, trim_prefix: 'mygroup')

      expect(lookup_path.prefix).to eq('/myproject/')
    end
  end
end
