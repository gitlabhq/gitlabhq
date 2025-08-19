# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/lib/tooling/ci_analytics/job_trace_downloader'

RSpec.describe Tooling::CiAnalytics::JobTraceDownloader, feature_category: :tooling do
  let(:api_url) { 'https://gitlab.com/api/v4' }
  let(:token) { 'glpat-1234567890abcdef' }
  let(:project_id) { '278964' }
  let(:job_id) { '10809465914' }

  let(:mock_http) { instance_double(Net::HTTP) }
  let(:mock_request) { instance_double(Net::HTTP::Get) }
  let(:mock_response) { instance_double(Net::HTTPResponse) }

  let(:downloader) do
    described_class.new(
      api_url: api_url,
      token: token,
      project_id: project_id
    )
  end

  before do
    allow(Net::HTTP).to receive(:new).and_return(mock_http)
    allow(Net::HTTP::Get).to receive(:new).and_return(mock_request)
    allow(mock_http).to receive(:use_ssl=)
    allow(mock_http).to receive(:request).and_return(mock_response)
    allow(mock_request).to receive(:[]=)
    allow(downloader).to receive(:puts)
  end

  describe '#initialize' do
    it 'sets instance variables from parameters' do
      instance = described_class.new(
        api_url: api_url,
        token: token,
        project_id: project_id
      )

      expect(instance.instance_variable_get(:@api_url)).to eq(api_url)
      expect(instance.instance_variable_get(:@token)).to eq(token)
      expect(instance.instance_variable_get(:@project_id)).to eq(project_id)
    end
  end

  describe '#download_job_trace' do
    let(:expected_url) { "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace" }

    context 'when download is successful' do
      let(:trace_content) { 'Job trace content here' * 100 }

      before do
        allow(mock_response).to receive_messages(
          code: '200',
          body: trace_content
        )
      end

      it 'constructs correct URL' do
        allow(URI).to receive(:parse).and_call_original

        downloader.download_job_trace(job_id)

        expect(URI).to have_received(:parse).with(expected_url)
      end

      it 'configures HTTP client correctly' do
        downloader.download_job_trace(job_id)

        uri = URI(expected_url)
        expect(Net::HTTP).to have_received(:new).with(uri.host, uri.port)
        expect(mock_http).to have_received(:use_ssl=).with(true)
      end

      it 'sets authorization header' do
        downloader.download_job_trace(job_id)

        expect(mock_request).to have_received(:[]=).with('PRIVATE-TOKEN', token)
      end

      it 'makes HTTP request' do
        downloader.download_job_trace(job_id)

        expect(mock_http).to have_received(:request).with(mock_request)
      end

      it 'returns trace content' do
        result = downloader.download_job_trace(job_id)

        expect(result).to eq(trace_content)
      end

      context 'with small trace' do
        let(:trace_content) { 'Small trace' }

        it 'processes small trace content successfully' do
          result = downloader.download_job_trace(job_id)

          expect(result).to eq(trace_content)
        end
      end

      context 'with large trace' do
        let(:trace_content) { 'Large trace content ' * 5000 }

        it 'processes large trace content successfully' do
          result = downloader.download_job_trace(job_id)

          expect(result).to eq(trace_content)
        end
      end
    end

    context 'when download fails' do
      before do
        allow(mock_response).to receive_messages(
          code: '404',
          body: ''
        )
      end

      it 'returns nil on download failure' do
        result = downloader.download_job_trace(job_id)

        expect(result).to be_nil
      end

      context 'with different error codes' do
        %w[401 403 500].each do |error_code|
          it "handles #{error_code} error correctly" do
            allow(mock_response).to receive_messages(
              code: error_code,
              body: ''
            )

            result = downloader.download_job_trace(job_id)

            expect(result).to be_nil
          end
        end
      end
    end

    context 'in integration scenarios' do
      context 'with real-world GitLab URLs' do
        let(:api_url) { 'https://gitlab.example.com/api/v4' }
        let(:project_id) { 'group/project' }
        let(:downloader) do
          described_class.new(
            api_url: api_url,
            token: token,
            project_id: project_id
          )
        end

        before do
          allow(mock_response).to receive_messages(
            code: '200',
            body: 'test content'
          )
          allow(downloader).to receive(:puts)
        end

        it 'constructs URLs with project paths correctly' do
          expected_uri = URI("#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace")
          allow(URI).to receive(:parse).and_call_original

          downloader.download_job_trace(job_id)

          expect(URI).to have_received(:parse).with(expected_uri.to_s)
        end
      end

      context 'when network request fails' do
        before do
          allow(mock_http).to receive(:request).and_raise(StandardError.new('Network error'))
        end

        it 'propagates network errors' do
          expect { downloader.download_job_trace(job_id) }.to raise_error(StandardError, 'Network error')
        end
      end

      context 'with empty trace content' do
        before do
          allow(mock_response).to receive_messages(
            code: '200',
            body: ''
          )
        end

        it 'handles empty content correctly' do
          result = downloader.download_job_trace(job_id)

          expect(result).to eq('')
        end
      end
    end
  end
end
