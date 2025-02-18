# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ValidateRemoteGitEndpointService, feature_category: :importers do
  include StubRequests

  let_it_be(:base_url) { 'http://demo.host/path' }
  let_it_be(:endpoint_url) { "#{base_url}/info/refs?service=git-upload-pack" }
  let_it_be(:endpoint_error_message) { "#{base_url} endpoint error:" }
  let_it_be(:body_error_message) { described_class::INVALID_BODY_MESSAGE }
  let_it_be(:content_type_error_message) { described_class::INVALID_CONTENT_TYPE_MESSAGE }

  describe '#execute' do
    let(:valid_response) do
      { status: 200,
        body: '001e# service=git-upload-pack',
        headers: { 'Content-Type': 'application/x-git-upload-pack-advertisement' } }
    end

    it 'correctly handles URLs with fragment' do
      allow(Gitlab::HTTP).to receive(:get)

      described_class.new(url: "#{base_url}#somehash").execute

      expect(Gitlab::HTTP).to have_received(:get).with(endpoint_url, basic_auth: nil, stream_body: true, follow_redirects: false)
    end

    context 'when uri is using git:// protocol' do
      subject { described_class.new(url: 'git://demo.host/repo') }

      it 'returns success' do
        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
      end
    end

    context 'when uri is using an invalid protocol' do
      subject { described_class.new(url: 'ssh://demo.host/repo') }

      it 'reports error when invalid URL is provided' do
        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
      end
    end

    context 'when uri is invalid' do
      subject { described_class.new(url: 'http:example.com') }

      it 'reports error when invalid URL is provided' do
        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
      end
    end

    context 'when receiving HTTP response' do
      subject { described_class.new(url: base_url) }

      it 'returns success when HTTP response is valid and contains correct payload' do
        stub_full_request(endpoint_url, method: :get).to_return(valid_response)

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
      end

      context 'when server reply with capitized 001e# reply (Bonobo server)' do
        let(:valid_response) do
          { status: 200,
            body: '001E# service=git-upload-pack',
            headers: { 'Content-Type': 'application/x-git-upload-pack-advertisement' } }
        end

        it 'returns success when HTTP response is valid and contains correct payload' do
          stub_full_request(endpoint_url, method: :get).to_return(valid_response)

          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.success?).to be(true)
        end
      end

      it 'reports error when status code is not 200' do
        error_response = { status: 401 }
        stub_full_request(endpoint_url, method: :get).to_return(error_response)

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq("#{endpoint_error_message} #{error_response[:status]}")
      end

      it 'reports error when invalid URL is provided' do
        result = described_class.new(url: 1).execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq('1 is not a valid URL')
      end

      it 'reports error when required header is missing' do
        stub_full_request(endpoint_url, method: :get).to_return(valid_response.merge({ headers: nil }))

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(content_type_error_message)
      end

      it 'reports error when body is too short' do
        stub_full_request(endpoint_url, method: :get).to_return(valid_response.merge({ body: 'invalid content' }))

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(body_error_message)
      end

      it 'reports error when body is in invalid format' do
        stub_full_request(endpoint_url, method: :get).to_return(valid_response.merge({ body: 'invalid long content with no git respons whatshowever' }))

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq(body_error_message)
      end

      it 'reports error when http exceptions are raised' do
        err = SocketError.new('dummy message')
        stub_full_request(endpoint_url, method: :get).to_raise(err)

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq("HTTP #{err.class.name.underscore} error: #{err.message}")
      end

      it 'reports error when other exceptions are raised' do
        err = StandardError.new('internal dummy message')
        stub_full_request(endpoint_url, method: :get).to_raise(err)

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq("Internal #{err.class.name.underscore} error: #{err.message}")
      end
    end

    context 'with auth credentials' do
      before do
        allow(Gitlab::HTTP).to receive(:get)
      end

      let(:user) { 'u$er' }
      let(:password) { 'pa$$w@rd' }

      context 'when credentials are provided via params' do
        let(:url) { "#{base_url}#somehash" }

        it 'sets basic auth from these credentials' do
          described_class.new(url: url, user: user, password: password).execute

          expect(Gitlab::HTTP).to have_received(:get).with(endpoint_url, basic_auth: { username: user, password: password }, stream_body: true, follow_redirects: false)
        end
      end

      context 'when credentials are provided in url' do
        let(:url) { "http://#{user}:#{password}@demo.host/path#somehash" }

        it 'passes basic auth from uri credentials' do
          described_class.new(url: url).execute

          expect(Gitlab::HTTP).to have_received(:get).with(endpoint_url, basic_auth: { username: user, password: password }, stream_body: true, follow_redirects: false)
        end
      end

      context 'when credentials are set via both params and url' do
        let(:url) { "http://uri_user:url_password@demo.host/path#somehash" }

        it 'prefers credentials via params' do
          described_class.new(url: url, user: user, password: password).execute

          expect(Gitlab::HTTP).to have_received(:get).with(endpoint_url, basic_auth: { username: user, password: password }, stream_body: true, follow_redirects: false)
        end
      end
    end
  end
end
