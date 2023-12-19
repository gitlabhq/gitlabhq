# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Clients::HTTP, feature_category: :importers do
  include ImportSpecHelper

  let(:url) { 'http://gitlab.example' }
  let(:token) { 'token' }
  let(:resource) { 'resource' }
  let(:version) { "#{BulkImport::MIN_MAJOR_VERSION}.0.0" }
  let(:enterprise) { false }
  let(:sidekiq_request_timeout) { described_class::SIDEKIQ_REQUEST_TIMEOUT }
  let(:response_double) { double(code: 200, success?: true, parsed_response: {}) }
  let(:metadata_response) do
    double(
      code: 200,
      success?: true,
      parsed_response: {
        'version' => version,
        'enterprise' => enterprise
      }
    )
  end

  subject { described_class.new(url: url, token: token) }

  shared_examples 'performs network request' do
    it 'performs network request' do
      expect(Gitlab::HTTP).to receive(method).with(*expected_args).and_return(response_double)

      subject.public_send(method, resource)
    end

    context 'error handling' do
      context 'when any known HTTP error occurs' do
        using RSpec::Parameterized::TableSyntax

        where(:exception_class) { Gitlab::HTTP::HTTP_ERRORS }

        with_them do
          it 'raises BulkImports::NetworkError' do
            allow(Gitlab::HTTP).to receive(method).and_raise(exception_class)

            expect { subject.public_send(method, resource) }.to raise_exception(BulkImports::NetworkError)
          end
        end
      end

      context 'when response is not success' do
        it 'raises BulkImports::NetworkError' do
          response_double = double(code: 503, success?: false, parsed_response: 'Error', request: double(path: double(path: '/test')))

          allow(Gitlab::HTTP).to receive(method).and_return(response_double)

          expect { subject.public_send(method, resource) }.to raise_exception(BulkImports::NetworkError, 'Unsuccessful response 503 from /test. Body: Error')
        end
      end
    end
  end

  describe '#get' do
    let(:method) { :get }

    include_examples 'performs network request' do
      let(:expected_args) do
        [
          'http://gitlab.example/api/v4/resource',
          hash_including(
            query: {
              page: described_class::DEFAULT_PAGE,
              per_page: described_class::DEFAULT_PER_PAGE,
              private_token: token
            },
            follow_redirects: true,
            resend_on_redirect: false,
            limit: 2
          )
        ]
      end
    end

    describe '#each_page' do
      let(:objects1) { [{ object: 1 }, { object: 2 }] }
      let(:objects2) { [{ object: 3 }, { object: 4 }] }
      let(:response1) { double(success?: true, headers: { 'x-next-page' => 2 }, parsed_response: objects1) }
      let(:response2) { double(success?: true, headers: {}, parsed_response: objects2) }

      before do
        stub_http_get('groups', { page: 1, per_page: 30 }, response1)
        stub_http_get('groups', { page: 2, per_page: 30 }, response2)
      end

      context 'with a block' do
        it 'yields every retrieved page to the supplied block' do
          pages = []

          subject.each_page(:get, 'groups') { |page| pages << page }

          expect(pages[0]).to be_an_instance_of(Array)
          expect(pages[1]).to be_an_instance_of(Array)

          expect(pages[0]).to eq(objects1)
          expect(pages[1]).to eq(objects2)
        end
      end

      context 'without a block' do
        it 'returns an Enumerator' do
          expect(subject.each_page(:get, :foo)).to be_an_instance_of(Enumerator)
        end
      end

      private

      def stub_http_get(path, query, response)
        uri = "http://gitlab.example/api/v4/#{path}"
        params = {
          query: { private_token: token },
          follow_redirects: true,
          resend_on_redirect: false,
          limit: 2
        }
        params[:query] = params[:query].merge(query)

        allow(Gitlab::HTTP).to receive(:get).with(uri, params).and_return(response)
      end
    end

    context 'when the request is asynchronous' do
      let(:expected_args) do
        [
          'http://gitlab.example/api/v4/resource',
          hash_including(
            query: {
              page: described_class::DEFAULT_PAGE,
              per_page: described_class::DEFAULT_PER_PAGE,
              private_token: token
            },
            follow_redirects: true,
            resend_on_redirect: false,
            limit: 2,
            timeout: sidekiq_request_timeout
          )
        ]
      end

      it 'sets a timeout that is double the default read timeout' do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)

        expect(Gitlab::HTTP).to receive(method).with(*expected_args).and_return(response_double)

        subject.public_send(method, resource)
      end
    end
  end

  describe '#post' do
    let(:method) { :post }

    include_examples 'performs network request' do
      let(:expected_args) do
        [
          'http://gitlab.example/api/v4/resource',
          hash_including(
            body: {},
            query: {
              page: described_class::DEFAULT_PAGE,
              per_page: described_class::DEFAULT_PER_PAGE,
              private_token: token
            },
            follow_redirects: true,
            resend_on_redirect: false,
            limit: 2
          )
        ]
      end
    end
  end

  describe '#head' do
    let(:method) { :head }

    include_examples 'performs network request' do
      let(:expected_args) do
        [
          'http://gitlab.example/api/v4/resource',
          hash_including(
            query: {
              page: described_class::DEFAULT_PAGE,
              per_page: described_class::DEFAULT_PER_PAGE,
              private_token: token
            },
            follow_redirects: true,
            resend_on_redirect: false,
            limit: 2
          )
        ]
      end
    end
  end

  describe '#stream' do
    it 'performs network request with stream_body option' do
      expected_args = [
        'http://gitlab.example/api/v4/resource',
        hash_including(
          stream_body: true,
          query: {
            page: described_class::DEFAULT_PAGE,
            per_page: described_class::DEFAULT_PER_PAGE,
            private_token: token
          },
          follow_redirects: true,
          resend_on_redirect: false,
          limit: 2
        )
      ]

      expect(Gitlab::HTTP).to receive(:get).with(*expected_args).and_return(response_double)

      subject.stream(resource)
    end
  end

  describe '#instance_version' do
    it 'returns version as an instance of Gitlab::VersionInfo' do
      response = { version: version }

      stub_request(:get, 'http://gitlab.example/api/v4/version?private_token=token')
        .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(subject.instance_version).to eq(Gitlab::VersionInfo.parse(version))
    end

    context 'when /version endpoint is not available' do
      it 'requests /metadata endpoint' do
        response = { version: version }

        stub_request(:get, 'http://gitlab.example/api/v4/version?private_token=token').to_return(status: 404)
        stub_request(:get, 'http://gitlab.example/api/v4/metadata?private_token=token')
          .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })

        expect(subject.instance_version).to eq(Gitlab::VersionInfo.parse(version))
      end

      context 'when /metadata endpoint returns a 401' do
        it 'raises a BulkImports:Error' do
          stub_request(:get, 'http://gitlab.example/api/v4/version?private_token=token').to_return(status: 404)
          stub_request(:get, 'http://gitlab.example/api/v4/metadata?private_token=token')
            .to_return(status: 401, body: "", headers: { 'Content-Type' => 'application/json' })

          expect { subject.instance_version }
            .to raise_exception(BulkImports::Error,
              "Check that the source instance base URL and the personal access token meet the necessary requirements.")
        end
      end

      context 'when /metadata endpoint returns a 403' do
        it 'raises a BulkImports:Error' do
          stub_request(:get, 'http://gitlab.example/api/v4/version?private_token=token').to_return(status: 404)
          stub_request(:get, 'http://gitlab.example/api/v4/metadata?private_token=token')
            .to_return(status: 403, body: "", headers: { 'Content-Type' => 'application/json' })

          expect { subject.instance_version }
            .to raise_exception(BulkImports::Error,
              "Check that the source instance base URL and the personal access token meet the necessary requirements.")
        end
      end

      context 'when /metadata endpoint returns a 404' do
        it 'raises a BulkImports:Error' do
          stub_request(:get, 'http://gitlab.example/api/v4/version?private_token=token').to_return(status: 404)
          stub_request(:get, 'http://gitlab.example/api/v4/metadata?private_token=token')
            .to_return(status: 404, body: "", headers: { 'Content-Type' => 'application/json' })

          expect { subject.instance_version }.to raise_exception(BulkImports::Error, 'Invalid source URL. Enter only the base URL of the source GitLab instance.')
        end
      end

      context 'when /metadata endpoint returns any other BulkImports::NetworkError' do
        it 'raises a BulkImports:NetworkError' do
          stub_request(:get, 'http://gitlab.example/api/v4/version?private_token=token').to_return(status: 404)
          stub_request(:get, 'http://gitlab.example/api/v4/metadata?private_token=token')
            .to_return(status: 418, body: "", headers: { 'Content-Type' => 'application/json' })

          expect { subject.instance_version }.to raise_exception(BulkImports::NetworkError)
        end
      end
    end
  end

  describe '#validate_instance_version!' do
    before do
      allow(subject).to receive(:instance_version).and_return(source_version)
    end

    context 'when instance version is greater than or equal to the minimum major version' do
      let(:source_version) { Gitlab::VersionInfo.new(14) }

      it { expect(subject.validate_instance_version!).to eq(true) }
    end

    context 'when instance version is less than the minimum major version' do
      let(:source_version) { Gitlab::VersionInfo.new(13, 10, 0) }

      it { expect { subject.validate_instance_version! }.to raise_exception(BulkImports::Error) }
    end
  end

  describe '#validate_import_scopes!' do
    context 'when the source_version is < 15.5' do
      let(:source_version) { Gitlab::VersionInfo.new(15, 0) }

      it 'skips validation' do
        allow(subject).to receive(:instance_version).and_return(source_version)

        expect(subject.validate_import_scopes!).to eq(true)
      end
    end

    context 'when source version is 15.5 or higher' do
      let(:source_version) { Gitlab::VersionInfo.new(15, 6) }

      before do
        allow(subject).to receive(:instance_version).and_return(source_version)
      end

      context 'when an HTTP error is raised' do
        let(:response) { { enterprise: false } }

        it 'raises BulkImports::NetworkError' do
          stub_request(:get, 'http://gitlab.example/api/v4/personal_access_tokens/self?private_token=token')
            .to_return(status: 404)

          expect { subject.validate_import_scopes! }.to raise_exception(BulkImports::NetworkError)
        end
      end

      context 'when scopes are valid' do
        it 'returns true' do
          stub_request(:get, 'http://gitlab.example/api/v4/personal_access_tokens/self?private_token=token')
            .to_return(status: 200, body: { 'scopes' => ['api'] }.to_json, headers: { 'Content-Type' => 'application/json' })

          expect(subject.validate_import_scopes!).to eq(true)
        end
      end

      context 'when scopes are invalid' do
        it 'raises a BulkImports error' do
          stub_request(:get, 'http://gitlab.example/api/v4/personal_access_tokens/self?private_token=token')
            .to_return(status: 200, body: { 'scopes' => ['read_user'] }.to_json, headers: { 'Content-Type' => 'application/json' })

          expect(subject.instance_version).to eq(Gitlab::VersionInfo.parse(source_version))
          expect { subject.validate_import_scopes! }.to raise_exception(BulkImports::Error)
        end
      end
    end
  end

  describe '#instance_enterprise' do
    let(:response) { { enterprise: false } }

    before do
      stub_request(:get, 'http://gitlab.example/api/v4/version?private_token=token')
        .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns source instance enterprise information' do
      expect(subject.instance_enterprise).to eq(false)
    end

    context 'when enterprise information is missing' do
      let(:response) { {} }

      it 'defaults to true' do
        expect(subject.instance_enterprise).to eq(true)
      end
    end
  end

  describe '#compatible_for_project_migration?' do
    before do
      allow(subject).to receive(:instance_version).and_return(Gitlab::VersionInfo.parse(version))
    end

    context 'when instance version is lower the the expected minimum' do
      let(:version) { '14.3.0' }

      it 'returns false' do
        expect(subject.compatible_for_project_migration?).to be false
      end
    end

    context 'when instance version is at least the expected minimum' do
      let(:version) { '14.4.4' }

      it 'returns true' do
        expect(subject.compatible_for_project_migration?).to be true
      end
    end
  end

  context 'when url is relative' do
    let(:url) { 'http://website.example/gitlab' }

    before do
      allow(Gitlab::HTTP).to receive(:get)
        .with('http://website.example/gitlab/api/v4/version', anything)
        .and_return(metadata_response)
    end

    it 'performs network request to a relative gitlab url' do
      expect(Gitlab::HTTP).to receive(:get).with('http://website.example/gitlab/api/v4/resource', anything).and_return(response_double)

      subject.get(resource)
    end
  end
end
