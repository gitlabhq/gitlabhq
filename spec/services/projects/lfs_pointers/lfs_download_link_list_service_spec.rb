# frozen_string_literal: true
require 'spec_helper'

describe Projects::LfsPointers::LfsDownloadLinkListService do
  let(:import_url) { 'http://www.gitlab.com/demo/repo.git' }
  let(:lfs_endpoint) { "#{import_url}/info/lfs/objects/batch" }
  let!(:project) { create(:project, import_url: import_url) }
  let(:new_oids) { { 'oid1' => 123, 'oid2' => 125 } }
  let(:remote_uri) { URI.parse(lfs_endpoint) }

  let(:objects_response) do
    body = new_oids.map do |oid, size|
      {
        'oid' => oid,
        'size' => size,
        'actions' => {
          'download' => { 'href' => "#{import_url}/gitlab-lfs/objects/#{oid}" }
        }
      }
    end

    Struct.new(:success?, :objects).new(true, body)
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
    response = instance_double(HTTParty::Response)
    allow(response).to receive(:body).and_return(objects_response.to_json)
    allow(response).to receive(:success?).and_return(true)
    allow(Gitlab::HTTP).to receive(:post).and_return(response)
  end

  describe '#execute' do
    it 'retrieves each download link of every non existent lfs object' do
      subject.execute(new_oids).each do |lfs_download_object|
        expect(lfs_download_object.link).to eq "#{import_url}/gitlab-lfs/objects/#{lfs_download_object.oid}"
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
    it 'raise error if request fails' do
      allow(Gitlab::HTTP).to receive(:post).and_return(Struct.new(:success?, :message).new(false, 'Failed request'))

      expect { subject.send(:get_download_links, new_oids) }.to raise_error(described_class::DownloadLinksError)
    end

    shared_examples 'JSON parse errors' do |body|
      it 'raises error' do
        response = instance_double(HTTParty::Response)
        allow(response).to receive(:body).and_return(body)
        allow(response).to receive(:success?).and_return(true)
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
