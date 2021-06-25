# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Clients::Graphql do
  let_it_be(:config) { create(:bulk_import_configuration) }

  subject { described_class.new(url: config.url, token: config.access_token) }

  describe '#execute' do
    let(:query) { '{ metadata { version } }' }
    let(:graphql_client_double) { double }
    let(:response_double) { double }

    before do
      stub_const('BulkImports::MINIMUM_COMPATIBLE_MAJOR_VERSION', version)
      allow(graphql_client_double).to receive(:execute)
      allow(subject).to receive(:client).and_return(graphql_client_double)
      allow(graphql_client_double).to receive(:execute).with(query).and_return(response_double)
      allow(response_double).to receive_message_chain(:data, :metadata, :version).and_return(version)
    end

    context 'when source instance is compatible' do
      let(:version) { '14.0.0' }

      it 'marks source instance as compatible' do
        subject.execute('test')

        expect(subject.instance_variable_get(:@compatible_instance_version)).to eq(true)
      end
    end

    context 'when source instance is incompatible' do
      let(:version) { '13.0.0' }

      it 'raises an error' do
        expect { subject.execute('test') }.to raise_error(::BulkImports::Error, "Unsupported GitLab Version. Minimum Supported Gitlab Version #{BulkImport::MINIMUM_GITLAB_MAJOR_VERSION}.")
      end
    end
  end
end
