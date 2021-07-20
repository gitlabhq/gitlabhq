# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportRequestWorker do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, source_full_path: 'foo/bar', bulk_import: bulk_import) }
  let_it_be(:version_url) { 'https://gitlab.example/api/v4/version' }

  let(:response_double) { double(code: 200, success?: true, parsed_response: {}) }
  let(:job_args) { [entity.id] }

  describe '#perform' do
    before do
      allow(Gitlab::HTTP)
        .to receive(:get)
        .with(version_url, anything)
        .and_return(double(code: 200, success?: true, parsed_response: { 'version' => Gitlab::VERSION }))
      allow(Gitlab::HTTP).to receive(:post).and_return(response_double)
    end

    include_examples 'an idempotent worker' do
      it 'requests relations export' do
        expected = "/groups/foo%2Fbar/export_relations"

        expect_next_instance_of(BulkImports::Clients::HTTP) do |client|
          expect(client).to receive(:post).with(expected).twice
        end

        perform_multiple(job_args)
      end
    end
  end
end
