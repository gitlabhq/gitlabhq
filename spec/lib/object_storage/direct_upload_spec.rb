# frozen_string_literal: true

require 'spec_helper'

describe ObjectStorage::DirectUpload do
  let(:region) { 'us-east-1' }
  let(:path_style) { false }
  let(:use_iam_profile) { false }
  let(:credentials) do
    {
      provider: 'AWS',
      aws_access_key_id: 'AWS_ACCESS_KEY_ID',
      aws_secret_access_key: 'AWS_SECRET_ACCESS_KEY',
      region: region,
      path_style: path_style,
      use_iam_profile: use_iam_profile
    }
  end

  let(:storage_url) { 'https://uploads.s3.amazonaws.com/' }

  let(:bucket_name) { 'uploads' }
  let(:object_name) { 'tmp/uploads/my-file' }
  let(:maximum_size) { 1.gigabyte }

  let(:direct_upload) { described_class.new(credentials, bucket_name, object_name, has_length: has_length, maximum_size: maximum_size) }

  before do
    Fog.unmock!
  end

  describe '#has_length' do
    context 'is known' do
      let(:has_length) { true }
      let(:maximum_size) { nil }

      it "maximum size is not required" do
        expect { direct_upload }.not_to raise_error
      end
    end

    context 'is unknown' do
      let(:has_length) { false }

      context 'and maximum size is specified' do
        let(:maximum_size) { 1.gigabyte }

        it "does not raise an error" do
          expect { direct_upload }.not_to raise_error
        end
      end

      context 'and maximum size is not specified' do
        let(:maximum_size) { nil }

        it "raises an error" do
          expect { direct_upload }.to raise_error /maximum_size has to be specified if length is unknown/
        end
      end
    end
  end

  describe '#to_hash' do
    subject { direct_upload.to_hash }

    shared_examples 'a valid S3 upload' do
      it_behaves_like 'a valid upload'

      it 'sets Workhorse client data' do
        expect(subject[:UseWorkhorseClient]).to eq(use_iam_profile)
        expect(subject[:RemoteTempObjectID]).to eq(object_name)

        object_store_config = subject[:ObjectStorage]
        expect(object_store_config[:Provider]).to eq 'AWS'

        s3_config = object_store_config[:S3Config]
        expect(s3_config[:Bucket]).to eq(bucket_name)
        expect(s3_config[:Region]).to eq(region)
        expect(s3_config[:PathStyle]).to eq(path_style)
        expect(s3_config[:UseIamProfile]).to eq(use_iam_profile)
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(use_workhorse_s3_client: false)
        end

        it 'does not enable Workhorse client' do
          expect(subject[:UseWorkhorseClient]).to be false
        end
      end

      context 'when V2 signatures are used' do
        before do
          credentials[:aws_signature_version] = 2
        end

        it 'does not enable Workhorse client' do
          expect(subject[:UseWorkhorseClient]).to be false
        end
      end

      context 'when V4 signatures are used' do
        before do
          credentials[:aws_signature_version] = 4
        end

        it 'enables the Workhorse client for instance profiles' do
          expect(subject[:UseWorkhorseClient]).to eq(use_iam_profile)
        end
      end
    end

    shared_examples 'a valid Google upload' do
      it_behaves_like 'a valid upload'

      it 'does not set Workhorse client data' do
        expect(subject.keys).not_to include(:UseWorkhorseClient, :RemoteTempObjectID, :ObjectStorage)
      end
    end

    shared_examples 'a valid upload' do
      it "returns valid structure" do
        expect(subject).to have_key(:Timeout)
        expect(subject[:GetURL]).to start_with(storage_url)
        expect(subject[:StoreURL]).to start_with(storage_url)
        expect(subject[:DeleteURL]).to start_with(storage_url)
        expect(subject[:CustomPutHeaders]).to be_truthy
        expect(subject[:PutHeaders]).to eq({})
      end
    end

    shared_examples 'a valid upload with multipart data' do
      before do
        stub_object_storage_multipart_init(storage_url, "myUpload")
      end

      it_behaves_like 'a valid upload'

      it "returns valid structure" do
        expect(subject).to have_key(:MultipartUpload)
        expect(subject[:MultipartUpload]).to have_key(:PartSize)
        expect(subject[:MultipartUpload][:PartURLs]).to all(start_with(storage_url))
        expect(subject[:MultipartUpload][:PartURLs]).to all(include('uploadId=myUpload'))
        expect(subject[:MultipartUpload][:CompleteURL]).to start_with(storage_url)
        expect(subject[:MultipartUpload][:CompleteURL]).to include('uploadId=myUpload')
        expect(subject[:MultipartUpload][:AbortURL]).to start_with(storage_url)
        expect(subject[:MultipartUpload][:AbortURL]).to include('uploadId=myUpload')
      end

      it 'uses only strings in query parameters' do
        expect(direct_upload.send(:connection)).to receive(:signed_url).at_least(:once) do |params|
          if params[:query]
            expect(params[:query].keys.all? { |key| key.is_a?(String) }).to be_truthy
          end
        end

        subject
      end
    end

    shared_examples 'a valid S3 upload without multipart data' do
      it_behaves_like 'a valid S3 upload'
      it_behaves_like 'a valid upload without multipart data'
    end

    shared_examples 'a valid S3 upload with multipart data' do
      it_behaves_like 'a valid S3 upload'
      it_behaves_like 'a valid upload with multipart data'
    end

    shared_examples 'a valid upload without multipart data' do
      it_behaves_like 'a valid upload'

      it "returns valid structure" do
        expect(subject).not_to have_key(:MultipartUpload)
      end
    end

    context 'when AWS is used' do
      context 'when length is known' do
        let(:has_length) { true }

        it_behaves_like 'a valid S3 upload without multipart data'

        context 'when path style is true' do
          let(:path_style) { true }
          let(:storage_url) { 'https://s3.amazonaws.com/uploads' }

          before do
            stub_object_storage_multipart_init(storage_url, "myUpload")
          end

          it_behaves_like 'a valid S3 upload without multipart data'
        end

        context 'when IAM profile is true' do
          let(:use_iam_profile) { true }
          let(:iam_credentials_url) { "http://169.254.169.254/latest/meta-data/iam/security-credentials/" }
          let(:iam_credentials) do
            {
              'AccessKeyId' => 'dummykey',
              'SecretAccessKey' => 'dummysecret',
              'Token' => 'dummytoken',
              'Expiration' => 1.day.from_now.xmlschema
            }
          end

          before do
            stub_request(:get, iam_credentials_url)
              .to_return(status: 200, body: "somerole", headers: {})
            stub_request(:get, "#{iam_credentials_url}somerole")
              .to_return(status: 200, body: iam_credentials.to_json, headers: {})
          end

          it_behaves_like 'a valid S3 upload without multipart data'
        end
      end

      context 'when length is unknown' do
        let(:has_length) { false }

        it_behaves_like 'a valid S3 upload with multipart data' do
          before do
            stub_object_storage_multipart_init(storage_url, "myUpload")
          end

          context 'when maximum upload size is 10MB' do
            let(:maximum_size) { 10.megabyte }

            it 'returns only 2 parts' do
              expect(subject[:MultipartUpload][:PartURLs].length).to eq(2)
            end

            it 'part size is minimum, 5MB' do
              expect(subject[:MultipartUpload][:PartSize]).to eq(5.megabyte)
            end
          end

          context 'when maximum upload size is 12MB' do
            let(:maximum_size) { 12.megabyte }

            it 'returns only 3 parts' do
              expect(subject[:MultipartUpload][:PartURLs].length).to eq(3)
            end

            it 'part size is rounded-up to 5MB' do
              expect(subject[:MultipartUpload][:PartSize]).to eq(5.megabyte)
            end
          end

          context 'when maximum upload size is 49GB' do
            let(:maximum_size) { 49.gigabyte }

            it 'returns maximum, 100 parts' do
              expect(subject[:MultipartUpload][:PartURLs].length).to eq(100)
            end

            it 'part size is rounded-up to 5MB' do
              expect(subject[:MultipartUpload][:PartSize]).to eq(505.megabyte)
            end
          end
        end
      end
    end

    context 'when Google is used' do
      let(:credentials) do
        {
          provider: 'Google',
          google_storage_access_key_id: 'GOOGLE_ACCESS_KEY_ID',
          google_storage_secret_access_key: 'GOOGLE_SECRET_ACCESS_KEY'
        }
      end

      let(:storage_url) { 'https://storage.googleapis.com/uploads/' }

      context 'when length is known' do
        let(:has_length) { true }

        it_behaves_like 'a valid Google upload'
        it_behaves_like 'a valid upload without multipart data'
      end

      context 'when length is unknown' do
        let(:has_length) { false }

        it_behaves_like 'a valid Google upload'
        it_behaves_like 'a valid upload without multipart data'
      end
    end
  end
end
