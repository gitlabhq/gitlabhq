# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::BaseService, feature_category: :cell do
  subject(:base_service) { described_class.new }

  describe '#initialize' do
    context 'when cell is disabled' do
      it 'raises an error when cell is not enabled' do
        expect(Gitlab.config.cell).to receive(:enabled).and_return(false)

        expect { base_service }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#service_credentials' do
    let(:ca_content) { 'ca_certificate' }
    let(:key_content) { 'private_key' }
    let(:cert_content) { 'certificate' }

    let(:ca_file) do
      Tempfile.new.tap do |f|
        f.write(ca_content)
        f.rewind
      end
    end

    let(:key_file) do
      Tempfile.new.tap do |f|
        f.write(key_content)
        f.rewind
      end
    end

    let(:cert_file) do
      Tempfile.new.tap do |f|
        f.write(cert_content)
        f.rewind
      end
    end

    let(:config) do
      {
        ca_file: ca_file.path,
        private_key_file: key_file.path,
        certificate_file: cert_file.path
      }
    end

    subject(:service_credentials) { base_service.send(:service_credentials) }

    before do
      stub_config(cell: { enabled: true, topology_service_client: config })
    end

    after do
      [key_file, cert_file, ca_file].each(&:close!)
    end

    shared_examples 'insecure credentials' do
      it 'creates insecure credentials' do
        expect(GRPC::Core::ChannelCredentials).to receive(:new).with(no_args)
        service_credentials
      end
    end

    context 'when all certificate files are present' do
      it 'creates credentials with the file contents' do
        expect(GRPC::Core::ChannelCredentials).to receive(:new).with(ca_content, key_content, cert_content)
        service_credentials
      end
    end

    context 'when ca_file is not present' do
      let(:config) do
        {
          ca_file: nil,
          private_key_file: key_file.path,
          certificate_file: cert_file.path
        }
      end

      it 'creates credentials with key and cert only' do
        expect(GRPC::Core::ChannelCredentials).to receive(:new).with(nil, key_content, cert_content)
        service_credentials
      end
    end

    context 'with missing private key' do
      context 'when private_key_file key is not defined in config' do
        let(:config) do
          {
            ca_file: ca_file.path,
            certificate_file: cert_file.path
          }
        end

        include_examples 'insecure credentials'
      end

      context 'when private_key_file value is nil' do
        let(:config) do
          {
            ca_file: ca_file.path,
            private_key_file: nil,
            certificate_file: cert_file.path
          }
        end

        include_examples 'insecure credentials'
      end
    end

    context 'with missing certificate' do
      context 'when certificate_file key is not defined in config' do
        let(:config) do
          {
            ca_file: ca_file.path,
            private_key_file: key_file.path
          }
        end

        include_examples 'insecure credentials'
      end

      context 'when certificate_file value is nil' do
        let(:config) do
          {
            ca_file: ca_file.path,
            private_key_file: key_file.path,
            certificate_file: nil
          }
        end

        include_examples 'insecure credentials'
      end
    end

    context 'when config values are empty strings' do
      let(:config) do
        {
          ca_file: ca_file.path,
          private_key_file: '',
          certificate_file: ''
        }
      end

      include_examples 'insecure credentials'
    end

    context 'when certificate files do not exist on filesystem' do
      let(:config) do
        {
          ca_file: ca_file.path,
          private_key_file: '/nonexistent/key.pem',
          certificate_file: '/nonexistent/cert.pem'
        }
      end

      include_examples 'insecure credentials'
    end
  end
end
