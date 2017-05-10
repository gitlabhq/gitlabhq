require 'spec_helper'

describe Gitlab::Elastic::Client do
  describe 'build' do
    let(:client) { described_class.build(params) }

    context 'without credentials' do
      let(:params) { { url: 'http://dummy-elastic:9200' } }

      it 'makes unsigned requests' do
        stub_request(:get, 'http://dummy-elastic:9200/foo/_all/1')
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: [:fake_response])

        expect(client.get(index: 'foo', id: 1)).to eq([:fake_response])
      end
    end

    context 'with AWS IAM credentials' do
      let(:params) do
        {
          url: 'http://example-elastic:9200',
          aws: true,
          aws_region: 'us-east-1',
          aws_access_key: '0',
          aws_secret_access_key: '0'
        }
      end

      it 'signs requests' do
        travel_to(Time.parse('20170303T133952Z')) do
          stub_request(:get, 'http://example-elastic:9200/foo/_all/1')
            .with(
              headers: {
               'Authorization'        => 'AWS4-HMAC-SHA256 Credential=0/20170303/us-east-1/es/aws4_request, SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date, Signature=4ba2aae19a476152dacf5a2191da67b0cf81b9d7152dab5c42b1bba701da19f1',
               'Content-Type'         => 'application/json',
               'X-Amz-Content-Sha256' => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
               'X-Amz-Date'           => '20170303T133952Z'
            })
            .to_return(status: 200, body: [:fake_response])

          expect(client.get(index: 'foo', id: 1)).to eq([:fake_response])
        end
      end
    end
  end
end
