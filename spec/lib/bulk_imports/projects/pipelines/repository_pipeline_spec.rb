# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::RepositoryPipeline, feature_category: :importers do
  include StubRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:parent, freeze: false) { create(:project) }
  let_it_be(:bulk_import, freeze: false) { create(:bulk_import, user: user) }
  let_it_be(:bulk_import_configuration) { create(:bulk_import_configuration, bulk_import: bulk_import) }

  let_it_be(:entity, freeze: false) do
    create(
      :bulk_import_entity,
      :project_entity,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Repository',
      destination_namespace: parent.full_path,
      project: parent
    )
  end

  let_it_be_with_reload(:tracker) { create(:bulk_import_tracker, entity: entity) }

  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:extracted_data) { BulkImports::Pipeline::ExtractedData.new(data: project_data) }

  subject(:pipeline) { described_class.new(context) }

  before do
    allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
      allow(extractor).to receive(:extract).and_return(extracted_data)
    end

    allow(pipeline).to receive(:set_source_objects_counter)
  end

  describe '#run' do
    context 'successfully imports repository' do
      let(:project_data) { { 'httpUrlToRepo' => 'http://test.git' } }

      it 'imports new repository into destination project with the validated resolved address' do
        url = project_data['httpUrlToRepo'].sub("://", "://oauth2:#{bulk_import_configuration.access_token}@")

        stub_dns(project_data['httpUrlToRepo'], ip_address: '8.8.8.9')

        expect(context.portable).to receive(:ensure_repository)
        expect(context.portable.repository).to receive(:fetch_as_mirror).with(url, resolved_address: '8.8.8.9')

        pipeline.run
      end
    end

    context 'project has no repository' do
      let(:project_data) { { 'httpUrlToRepo' => '' } }

      it 'skips repository import' do
        expect(context.portable).not_to receive(:ensure_repository)
        expect(context.portable.repository).not_to receive(:fetch_as_mirror)

        pipeline.run
      end
    end

    context 'blocked local networks' do
      let(:project_data) { { 'httpUrlToRepo' => 'http://localhost/foo.git' } }

      it 'prevents import' do
        allow(Gitlab.config.gitlab).to receive(:host).and_return('notlocalhost.gitlab.com')
        allow(Gitlab::CurrentSettings).to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(false)

        pipeline.run

        expect(context.entity.failed?).to be(true)
      end
    end

    context 'when scheme is blocked' do
      let(:project_data) { { 'httpUrlToRepo' => 'file://example/tmp/foo.git' } }

      it 'prevents import' do
        pipeline.run

        expect(context.entity.failed?).to be(true)
        expect(context.entity.failures.first).to be_present
        expect(context.entity.failures.first.exception_message).to eq('Only allowed schemes are http, https')
      end
    end
  end

  describe '#after_run' do
    it 'executes housekeeping service after import' do
      service = instance_double(::Repositories::HousekeepingService)

      expect(::Repositories::HousekeepingService).to receive(:new).with(context.portable, :gc).and_return(service)
      expect(service).to receive(:execute)

      pipeline.after_run(context)
    end
  end

  describe '#get_resolved_address' do
    let(:url) { 'https://example.com/foo.git' }

    subject(:resolved_address) { pipeline.send(:get_resolved_address, url) }

    context 'when the resolved host is present and the scheme is http(s)' do
      it 'returns the validated hostname' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('https://example.com/foo.git'), '93.184.216.34'])

        expect(resolved_address).to eq('example.com')
      end
    end

    context 'when the resolved host is blank' do
      it 'returns an empty string' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('https://example.com/foo.git'), nil])

        expect(resolved_address).to eq('')
      end
    end

    context 'when the scheme is not http(s)' do
      it 'returns an empty string' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('ssh://example.com/foo.git'), '93.184.216.34'])

        expect(resolved_address).to eq('')
      end
    end
  end

  describe '#dns_rebind_protection?' do
    subject(:dns_rebind_protection) { pipeline.send(:dns_rebind_protection?) }

    context 'when an http proxy is configured' do
      it 'returns false' do
        allow(Gitlab).to receive(:http_proxy_env?).and_return(true)

        expect(dns_rebind_protection).to be(false)
      end
    end

    context 'when no http proxy is configured' do
      it 'returns the current setting' do
        allow(Gitlab).to receive(:http_proxy_env?).and_return(false)
        allow(Gitlab::CurrentSettings).to receive(:dns_rebinding_protection_enabled?).and_return(true)

        expect(dns_rebind_protection).to be(true)
      end
    end
  end
end
