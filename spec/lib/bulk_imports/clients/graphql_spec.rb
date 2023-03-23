# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Clients::Graphql, feature_category: :importers do
  let_it_be(:config) { create(:bulk_import_configuration) }

  subject { described_class.new(url: config.url, token: config.access_token) }

  describe '#execute' do
    let(:query) { '{ metadata { version } }' }
    let(:graphql_client_double) { double }
    let(:response_double) { double }
    let(:version) { '14.0.0' }

    describe 'source instance validation' do
      before do
        allow(graphql_client_double).to receive(:execute)
        allow(subject).to receive(:client).and_return(graphql_client_double)
        allow(graphql_client_double).to receive(:execute).with(query).and_return(response_double)
        allow(response_double).to receive_message_chain(:data, :metadata, :version).and_return(version)
      end

      context 'when source instance is compatible' do
        it 'marks source instance as compatible' do
          subject.execute('test')

          expect(subject.instance_variable_get(:@compatible_instance_version)).to eq(true)
        end
      end

      context 'when source instance is incompatible' do
        let(:version) { '13.0.0' }

        it 'raises an error' do
          expect { subject.execute('test') }.to raise_error(::BulkImports::Error, "Unsupported GitLab version. Minimum supported version is 14.")
        end
      end
    end

    describe 'network errors' do
      before do
        allow(Gitlab::HTTP)
          .to receive(:post)
          .and_return(response_double)
      end

      context 'when response cannot be parsed' do
        let(:response_double) { instance_double(HTTParty::Response, body: 'invalid', success?: true) }

        it 'raises network error' do
          expect { subject.execute('test') }.to raise_error(BulkImports::NetworkError, /unexpected character/)
        end
      end

      context 'when response is unsuccessful' do
        let(:response_double) { instance_double(HTTParty::Response, success?: false, code: 503) }

        it 'raises network error' do
          allow(response_double).to receive_message_chain(:request, :path, :path).and_return('foo/bar')

          expect { subject.execute('test') }.to raise_error(BulkImports::NetworkError, 'Unsuccessful response 503 from foo/bar')
        end
      end
    end
  end
end
