# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Clients::Graphql, feature_category: :importers do
  let_it_be(:config) { create(:bulk_import_configuration) }

  subject { described_class.new(url: config.url, token: config.access_token) }

  describe '#execute' do
    let(:response_double) { double }

    describe 'network errors' do
      before do
        allow(Gitlab::HTTP)
          .to receive(:post)
          .with(an_instance_of(String), a_hash_including(timeout: 60))
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
