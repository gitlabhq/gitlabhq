# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GetMergeRequestPipelinesService, feature_category: :mcp_server do
  let(:service) { described_class.new(name: 'get_merge_request_pipelines') }

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to eq('Get pipelines for a merge request.')
    end
  end

  describe '#input_schema' do
    it 'returns the correct schema' do
      schema = service.input_schema

      expect(schema[:type]).to eq('object')
      expect(schema[:required]).to eq(%w[id merge_request_iid])
      expect(schema[:properties][:id][:type]).to eq('string')
      expect(schema[:properties][:id][:minLength]).to eq(1)
      expect(schema[:properties][:merge_request_iid][:type]).to eq('integer')
      expect(schema[:properties][:page][:type]).to eq('integer')
      expect(schema[:properties][:page][:minimum]).to eq(1)
      expect(schema[:properties][:per_page][:type]).to eq('integer')
      expect(schema[:properties][:per_page][:minimum]).to eq(1)
    end
  end

  describe '#execute' do
    let(:oauth_token) { 'token_123' }

    context 'with valid arguments' do
      let(:api_response) do
        instance_double(Gitlab::HTTP::Response, body: response_body, success?: success, code: response_code)
      end

      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(api_response)
      end

      context 'with successful response' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) do
          [
            {
              'id' => 77,
              'sha' => '959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d',
              'ref' => 'main',
              'status' => 'success'
            },
            {
              'id' => 76,
              'sha' => '123e04d7c7a30600c894bd3c0cd0e1ce7f42c11d',
              'ref' => 'feature-branch',
              'status' => 'failed'
            }
          ].to_json
        end

        let(:arguments) do
          { id: 'test-project', merge_request_iid: 10 }
        end

        it 'returns success response' do
          result = service.execute(oauth_token, arguments)

          expect(result[:isError]).to be false
          expect(result[:content].first[:type]).to eq('text')
          expect(result[:content].first[:text]).to include('Pipeline #77 - success (main)')
          expect(result[:content].first[:text]).to include('SHA: 959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d')
          expect(result[:content].first[:text]).to include('Pipeline #76 - failed (feature-branch)')
          expect(result[:content].first[:text]).to include('SHA: 123e04d7c7a30600c894bd3c0cd0e1ce7f42c11d')
          expect(result[:structuredContent][:items].length).to eq(2)
          expect(result[:structuredContent][:metadata][:count]).to eq(2)
          expect(result[:structuredContent][:metadata][:has_more]).to be false
          expect(result[:structuredContent][:items].first['id']).to eq(77)
          expect(result[:structuredContent][:items].first['status']).to eq('success')
          expect(result[:structuredContent][:items].first['ref']).to eq('main')
          expect(result[:structuredContent][:items].second['id']).to eq(76)
          expect(result[:structuredContent][:items].second['status']).to eq('failed')
          expect(result[:structuredContent][:items].second['ref']).to eq('feature-branch')
        end

        it 'makes request with correct URL' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/pipelines",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end

        context 'with pagination parameters' do
          let(:arguments) do
            { id: 'test-project', merge_request_iid: 10, page: 2, per_page: 50 }
          end

          it 'includes pagination parameters in query' do
            service.execute(oauth_token, arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/pipelines",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'),
                query: { page: 2, per_page: 50 },
                verify: false
              )
            )
          end
        end

        context 'with only page parameter' do
          let(:arguments) do
            { id: 'test-project', merge_request_iid: 10, page: 3 }
          end

          it 'includes only page parameter in query' do
            service.execute(oauth_token, arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/pipelines",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'), query: { page: 3 }, verify: false
              )
            )
          end
        end

        context 'with only per_page parameter' do
          let(:arguments) do
            { id: 'test-project', merge_request_iid: 10, per_page: 25 }
          end

          it 'includes only per_page parameter in query' do
            service.execute(oauth_token, arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/pipelines",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'), query: { per_page: 25 }, verify: false
              )
            )
          end
        end
      end

      context 'with single pipeline' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) do
          [
            {
              'id' => 77,
              'sha' => '959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d',
              'ref' => 'main',
              'status' => 'success'
            }
          ].to_json
        end

        let(:arguments) do
          { id: 'test-project', merge_request_iid: 10 }
        end

        it 'returns single pipeline text' do
          result = service.execute(oauth_token, arguments)

          expect(result[:content].first[:text]).to include('Pipeline #77 - success (main)')
          expect(result[:content].first[:text]).to include('SHA: 959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d')
        end
      end

      context 'with project ID that needs encoding' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) { [].to_json }
        let(:arguments) do
          { id: 'foo-bar/gitlab', merge_request_iid: 1 }
        end

        it 'URL encodes the project ID' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/foo-bar%2Fgitlab/merge_requests/1/pipelines",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end
      end

      context 'with empty pipelines response' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) { [].to_json }
        let(:arguments) do
          { id: 'test-project', merge_request_iid: 10 }
        end

        it 'returns success response with empty array' do
          result = service.execute(oauth_token, arguments)

          expect(result[:isError]).to be false
          expect(result[:content]).to match_array([{ type: 'text', text: '' }])
          expect(result[:structuredContent]).to eq({ items: [], metadata: { count: 0, has_more: false } })
        end
      end

      context 'with different pipeline statuses' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) do
          [
            {
              'id' => 78,
              'sha' => '111e04d7c7a30600c894bd3c0cd0e1ce7f42c11d',
              'ref' => 'main',
              'status' => 'running'
            },
            {
              'id' => 79,
              'sha' => '222e04d7c7a30600c894bd3c0cd0e1ce7f42c11d',
              'ref' => 'develop',
              'status' => 'pending'
            }
          ].to_json
        end

        let(:arguments) do
          { id: 'test-project', merge_request_iid: 10 }
        end

        it 'formats different statuses correctly' do
          result = service.execute(oauth_token, arguments)

          expect(result[:content].first[:text]).to include('Pipeline #78 - running (main)')
          expect(result[:content].first[:text]).to include('Pipeline #79 - pending (develop)')
        end
      end
    end

    context 'with missing required field' do
      let(:arguments) do
        { id: 'test-project' }
      end

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('merge_request_iid is missing')
      end
    end

    context 'with missing project id' do
      let(:arguments) do
        { merge_request_iid: 10 }
      end

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('id is missing')
      end
    end
  end
end
