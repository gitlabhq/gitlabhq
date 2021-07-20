# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::LfsPointers::LfsDownloadLinkListService do
  let(:import_url) { 'http://www.gitlab.com/demo/repo.git' }
  let(:lfs_endpoint) { "#{import_url}/info/lfs/objects/batch" }
  let!(:project) { create(:project, import_url: import_url) }
  let(:new_oids) { { 'oid1' => 123, 'oid2' => 125 } }
  let(:headers) { { 'X-Some-Header' => '456' }}
  let(:remote_uri) { URI.parse(lfs_endpoint) }

  let(:request_object) { HTTParty::Request.new(Net::HTTP::Post, '/') }
  let(:parsed_block) { lambda {} }
  let(:success_net_response) { Net::HTTPOK.new('', '', '') }
  let(:response) { Gitlab::HTTP::Response.new(request_object, net_response, parsed_block) }

  def objects_response(oids)
    body = oids.map do |oid, size|
      {
        'oid' => oid, 'size' => size,
        'actions' => {
          'download' => { 'href' => "#{import_url}/gitlab-lfs/objects/#{oid}", header: headers }
        }
      }
    end

    Struct.new(:success?, :objects).new(true, body).to_json
  end

  def custom_response(net_response, body = nil)
    allow(net_response).to receive(:body).and_return(body)
    Gitlab::HTTP::Response.new(request_object, net_response, parsed_block)
  end

  let(:invalid_object_response) do
    [
      'oid' => 'whatever',
      'size' => 123
    ]
  end

  subject { described_class.new(project, remote_uri: remote_uri) }

  before do
    allow(project).to receive(:lfs_enabled?).and_return(true)

    response = custom_response(success_net_response, objects_response(new_oids))
    allow(Gitlab::HTTP).to receive(:post).and_return(response)
  end

  describe '#execute' do
    let(:download_objects) { subject.execute(new_oids) }

    it 'retrieves each download link of every non existent lfs object' do
      download_objects.each do |lfs_download_object|
        expect(lfs_download_object.link).to eq "#{import_url}/gitlab-lfs/objects/#{lfs_download_object.oid}"
      end
    end

    it 'stores headers' do
      download_objects.each do |lfs_download_object|
        expect(lfs_download_object.headers).to eq(headers)
      end
    end

    context 'when lfs objects size is larger than the batch size' do
      def stub_successful_request(batch)
        response = custom_response(success_net_response, objects_response(batch))
        stub_request(batch, response)
      end

      def stub_entity_too_large_error_request(batch)
        entity_too_large_net_response = Net::HTTPRequestEntityTooLarge.new('', '', '')
        response = custom_response(entity_too_large_net_response)
        stub_request(batch, response)
      end

      def stub_request(batch, response)
        expect(Gitlab::HTTP).to receive(:post).with(
          remote_uri,
          {
            body: { operation: 'download', objects: batch.map { |k, v| { oid: k, size: v } } }.to_json,
            headers: subject.send(:headers)
          }
        ).and_return(response)
      end

      let(:new_oids) { { 'oid1' => 123, 'oid2' => 125, 'oid3' => 126, 'oid4' => 127, 'oid5' => 128 } }

      context 'when batch size' do
        before do
          stub_const("#{described_class.name}::REQUEST_BATCH_SIZE", 2)

          data = new_oids.to_a
          stub_successful_request([data[0], data[1]])
          stub_successful_request([data[2], data[3]])
          stub_successful_request([data[4]])
        end

        it 'retreives them in batches' do
          subject.execute(new_oids).each do |lfs_download_object|
            expect(lfs_download_object.link).to eq "#{import_url}/gitlab-lfs/objects/#{lfs_download_object.oid}"
          end
        end
      end

      context 'when request fails with PayloadTooLarge error' do
        let(:error_class) { described_class::DownloadLinksRequestEntityTooLargeError }

        context 'when the smaller batch eventually works' do
          before do
            stub_const("#{described_class.name}::REQUEST_BATCH_SIZE", 5)

            data = new_oids.to_a

            # with the batch size of 5
            stub_entity_too_large_error_request(data)

            # with the batch size of 2
            stub_successful_request([data[0], data[1]])
            stub_successful_request([data[2], data[3]])
            stub_successful_request([data[4]])
          end

          it 'retreives them eventually and logs exceptions' do
            expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
              an_instance_of(error_class), project_id: project.id, batch_size: 5, oids_count: 5
            )

            subject.execute(new_oids).each do |lfs_download_object|
              expect(lfs_download_object.link).to eq "#{import_url}/gitlab-lfs/objects/#{lfs_download_object.oid}"
            end
          end
        end

        context 'when batch size cannot be any smaller' do
          before do
            stub_const("#{described_class.name}::REQUEST_BATCH_SIZE", 5)

            data = new_oids.to_a

            # with the batch size of 5
            stub_entity_too_large_error_request(data)

            # with the batch size of 2
            stub_entity_too_large_error_request([data[0], data[1]])
          end

          it 'raises an error and logs exceptions' do
            expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
              an_instance_of(error_class), project_id: project.id, batch_size: 5, oids_count: 5
            )
            expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
              an_instance_of(error_class), project_id: project.id, batch_size: 2, oids_count: 5
            )
            expect { subject.execute(new_oids) }.to raise_error(described_class::DownloadLinksError)
          end
        end
      end
    end

    context 'credentials' do
      context 'when the download link and the lfs_endpoint have the same host' do
        context 'when lfs_endpoint has credentials' do
          let(:import_url) { 'http://user:password@www.gitlab.com/demo/repo.git' }

          it 'adds credentials to the download_link' do
            result = subject.execute(new_oids)

            result.each do |lfs_download_object|
              expect(lfs_download_object.link.starts_with?('http://user:password@')).to be_truthy
            end
          end
        end

        context 'when lfs_endpoint does not have any credentials' do
          it 'does not add any credentials' do
            result = subject.execute(new_oids)

            result.each do |lfs_download_object|
              expect(lfs_download_object.link.starts_with?('http://user:password@')).to be_falsey
            end
          end
        end
      end

      context 'when the download link and the lfs_endpoint have different hosts' do
        let(:import_url_with_credentials) { 'http://user:password@www.otherdomain.com/demo/repo.git' }
        let(:lfs_endpoint) { "#{import_url_with_credentials}/info/lfs/objects/batch" }

        it 'downloads without any credentials' do
          result = subject.execute(new_oids)

          result.each do |lfs_download_object|
            expect(lfs_download_object.link.starts_with?('http://user:password@')).to be_falsey
          end
        end
      end
    end
  end

  describe '#get_download_links' do
    context 'if request fails' do
      before do
        request_timeout_net_response = Net::HTTPRequestTimeout.new('', '', '')
        response = custom_response(request_timeout_net_response)
        allow(Gitlab::HTTP).to receive(:post).and_return(response)
      end

      it 'raises an error' do
        expect { subject.send(:get_download_links, new_oids) }.to raise_error(described_class::DownloadLinksError)
      end
    end

    shared_examples 'JSON parse errors' do |body|
      it 'raises an error' do
        response = custom_response(success_net_response)
        allow(response).to receive(:body).and_return(body)
        allow(Gitlab::HTTP).to receive(:post).and_return(response)

        expect { subject.send(:get_download_links, new_oids) }.to raise_error(described_class::DownloadLinksError)
      end
    end

    it_behaves_like 'JSON parse errors', '{'
    it_behaves_like 'JSON parse errors', '{}'
    it_behaves_like 'JSON parse errors', '{ foo: 123 }'
  end

  describe '#parse_response_links' do
    it 'does not add oid entry if href not found' do
      expect(subject).to receive(:log_error).with("Link for Lfs Object with oid whatever not found or invalid.")

      result = subject.send(:parse_response_links, invalid_object_response)

      expect(result).to be_empty
    end
  end
end
