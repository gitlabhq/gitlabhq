require 'spec_helper'

describe Gitlab::Elastic::Client do
  let(:creds_valid_response) do
    '{
      "Code": "Success",
      "Type": "AWS-HMAC",
      "AccessKeyId": "0",
      "SecretAccessKey": "0",
      "Token": "token",
      "Expiration": "2018-12-16T01:51:37Z",
      "LastUpdated": "2009-11-23T0:00:00Z"
    }'
  end

  let(:creds_fail_response) do
    '{
      "Code": "ErrorCode",
      "Message": "ErrorMsg",
      "LastUpdated": "2009-11-23T0:00:00Z"
    }'
  end

  def stub_instance_credentials(creds_response)
    stub_request(:get, "http://169.254.169.254/latest/meta-data/iam/security-credentials/")
      .to_return(status: 200, body: "RoleName", headers: {})
    stub_request(:get, "http://169.254.169.254/latest/meta-data/iam/security-credentials/RoleName")
      .to_return(status: 200, body: creds_response, headers: {})
  end

  describe '.build' do
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

    context 'with AWS IAM static credentials' do
      let(:params) do
        {
          url: 'http://example-elastic:9200',
          aws: true,
          aws_region: 'us-east-1',
          aws_access_key: '0',
          aws_secret_access_key: '0'
        }
      end

      it 'signs_requests' do
        stub_instance_credentials(creds_fail_response)
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

  describe '.resolve_aws_credentials' do
    let(:creds) { described_class.resolve_aws_credentials(params) }

    context 'when the AWS IAM static credentials are valid' do
      let(:params) do
        {
          url: 'http://example-elastic:9200',
          aws: true,
          aws_region: 'us-east-1',
          aws_access_key: '0',
          aws_secret_access_key: '0'
        }
      end

      it 'returns credentials from static credentials without making an HTTP request' do
        expect(creds.credentials.access_key_id).to eq '0'
        expect(creds.credentials.secret_access_key).to eq '0'
      end
    end

    context 'when the AWS IAM static credentials are invalid' do
      context 'with AWS ec2 instance profile' do
        let(:params) do
          {
            url: 'http://example-elastic:9200',
            aws: true,
            aws_region: 'us-east-1'
          }
        end

        it 'returns credentials from ec2 instance profile' do
          stub_instance_credentials(creds_valid_response)

          expect(creds.credentials.access_key_id).to eq '0'
          expect(creds.credentials.secret_access_key).to eq '0'
        end
      end

      context 'with AWS no credentials' do
        let(:params) do
          {
            url: 'http://example-elastic:9200',
            aws: true,
            aws_region: 'us-east-1'
          }
        end

        it 'returns nil' do
          stub_instance_credentials(creds_fail_response)

          expect(creds).to be_nil
        end
      end
    end
  end
end
