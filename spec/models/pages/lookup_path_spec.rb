# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::LookupPath do
  let_it_be(:project) do
    create(:project, :pages_private, pages_https_only: true)
  end

  subject(:lookup_path) { described_class.new(project) }

  before do
    stub_pages_setting(access_control: true, external_https: ["1.1.1.1:443"])
    stub_artifacts_object_storage
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
    shared_examples 'uses disk storage' do
      it 'sets the source type to "file"' do
        expect(lookup_path.source[:type]).to eq('file')
      end

      it 'sets the source path to the project full path suffixed with "public/' do
        expect(lookup_path.source[:path]).to eq(project.full_path + "/public/")
      end
    end

    include_examples 'uses disk storage'

    context 'when artifact_id from build job is present in pages metadata' do
      let(:artifacts_archive) { create(:ci_job_artifact, :zip, :remote_store, project: project) }

      before do
        project.mark_pages_as_deployed(artifacts_archive: artifacts_archive)
      end

      it 'sets the source type to "zip"' do
        expect(lookup_path.source[:type]).to eq('zip')
      end

      it 'sets the source path to the artifacts archive URL' do
        Timecop.freeze do
          expect(lookup_path.source[:path]).to eq(artifacts_archive.file.url(expire_at: 1.day.from_now))
          expect(lookup_path.source[:path]).to include("Expires=86400")
        end
      end

      context 'when artifact is not uploaded to object storage' do
        let(:artifacts_archive) { create(:ci_job_artifact, :zip) }

        include_examples 'uses disk storage'
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(pages_artifacts_archive: false)
        end

        include_examples 'uses disk storage'
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
