# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkhorseHelper, feature_category: :source_code_management do
  describe "#content_disposition_for_blob" do
    subject { helper.content_disposition_for_blob(blob, inline) }

    context 'when Content-Disposition is inline' do
      let(:inline) { true }

      context 'when blob is XHTML' do
        let(:blob) { instance_double(Gitlab::Git::Blob, name: 'test.xhtml.xhtml') }

        let(:content_disposition) do
          ActionDispatch::Http::ContentDisposition.format(disposition: 'inline', filename: 'test')
        end

        it { is_expected.to eq(content_disposition) }
      end

      context 'when blob is not XHTML' do
        let(:blob) { instance_double(Gitlab::Git::Blob, name: 'test.xml') }
        let(:content_disposition) { 'inline' }

        it { is_expected.to eq(content_disposition) }
      end
    end

    context 'when Content-Disposition is attachment' do
      let(:inline) { false }
      let(:blob) { instance_double(Gitlab::Git::Blob, name: 'test.pdf') }

      let(:content_disposition) do
        ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: 'test.pdf')
      end

      it { is_expected.to eq(content_disposition) }
    end
  end

  describe '#send_dependency' do
    let(:dependency_headers) do
      {
        'Authorization' => ["Bearer #{Devise.friendly_token}"],
        'Accept' => ['application/vnd.docker.distribution.manifest.v2+json']
      }
    end

    let(:url) { 'https://registry-1.docker.io/v2/library/ruby/manifests/2.3.5-alpine' }
    let(:filename) { 'alpine:sha256:a0264d60f80df12bc1e6dd98bae6c43debe6667c0ba482711f0d806493467a46.json' }
    let(:args) { [dependency_headers, url, filename] }
    let(:ssrf_filter) { nil }
    let(:headers) { {} }

    let(:content_disposition) do
      ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: filename)
    end

    subject(:send_dependency) { helper.send_dependency(*args) }

    before do
      allow(helper).to receive(:headers).and_return(headers)
    end

    context 'for HTTP headers' do
      before do
        allow(helper).to receive(:head).with(:ok)

        send_dependency
      end

      shared_examples 'setting the Workhorse headers' do
        it 'sets the headers' do
          command, params = decode_workhorse_header(headers['Gitlab-Workhorse-Send-Data'])
          expected_params = {
            'AllowLocalhost' => true,
            'Headers' => dependency_headers,
            'RestrictForwardedResponseHeaders' => { 'AllowList' => [], 'Enabled' => false },
            'SSRFFilter' => ssrf_filter,
            'Url' => url
          }.compact_blank

          expect(command).to eq('send-dependency')
          expect(params).to eq(expected_params)
        end
      end

      it_behaves_like 'setting the Workhorse headers'

      it 'sets HTTP headers' do
        expect(headers).to include('Content-Type' => 'application/gzip', 'Content-Disposition' => content_disposition)
      end

      context 'when ssrf_filter argument is `true`' do
        let(:ssrf_filter) { true }
        let(:ssrf_params) { { ssrf_filter: ssrf_filter } }

        subject(:send_dependency) { helper.send_dependency(*args, ssrf_params: ssrf_params) }

        it_behaves_like 'setting the Workhorse headers'
      end
    end

    context 'for HTTP status' do
      it 'sets HTTP status 200' do
        expect(helper).to receive(:head).with(:ok)

        send_dependency
      end
    end
  end

  def decode_workhorse_header(value)
    command, encoded_params = value.split(":")
    params = Gitlab::Json.parse(Base64.urlsafe_decode64(encoded_params))

    [command, params]
  end
end
