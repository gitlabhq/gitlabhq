# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GetPipelineJobsService, feature_category: :mcp_server do
  let(:service) { described_class.new(name: 'get_pipeline_jobs') }

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to eq('Get all jobs associated with a pipeline.')
    end
  end

  describe '#input_schema' do
    it 'returns the correct schema' do
      schema = service.input_schema

      expect(schema[:type]).to eq('object')
      expect(schema[:required]).to eq(%w[id pipeline_id])
      expect(schema[:properties][:id][:type]).to eq('string')
      expect(schema[:properties][:id][:minLength]).to eq(1)
      expect(schema[:properties][:pipeline_id][:type]).to eq('integer')
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
              'id' => 123,
              'name' => 'build',
              'stage' => 'build',
              'status' => 'success',
              'created_at' => '2024-01-15T10:30:00.000+00:00',
              'started_at' => '2024-01-15T10:31:00.000+00:00',
              'finished_at' => '2024-01-15T10:35:00.000+00:00',
              'duration' => 240.5,
              'web_url' => 'https://gitlab.com/test-project/-/jobs/123'
            },
            {
              'id' => 124,
              'name' => 'test',
              'stage' => 'test',
              'status' => 'failed',
              'created_at' => '2024-01-15T10:35:00.000+00:00',
              'started_at' => '2024-01-15T10:36:00.000+00:00',
              'finished_at' => '2024-01-15T10:40:00.000+00:00',
              'duration' => 300.2,
              'web_url' => 'https://gitlab.com/test-project/-/jobs/124'
            }
          ].to_json
        end

        let(:arguments) do
          { id: 'test-project', pipeline_id: 456 }
        end

        it 'returns success response' do
          result = service.execute(oauth_token, arguments)
          expect(result[:isError]).to be false
          expect(result[:content].first[:type]).to eq('text')
          expect(result[:content].first[:text]).to include('https://gitlab.com/test-project/-/jobs/123')
          expect(result[:content].first[:text]).to include('https://gitlab.com/test-project/-/jobs/124')
          expect(result[:structuredContent][:items].length).to eq(2)
          expect(result[:structuredContent][:metadata][:count]).to eq(2)
          expect(result[:structuredContent][:metadata][:has_more]).to be false
          expect(result[:structuredContent][:items].first['id']).to eq(123)
          expect(result[:structuredContent][:items].first['name']).to eq('build')
          expect(result[:structuredContent][:items].first['status']).to eq('success')
          expect(result[:structuredContent][:items].second['id']).to eq(124)
          expect(result[:structuredContent][:items].second['name']).to eq('test')
          expect(result[:structuredContent][:items].second['status']).to eq('failed')
        end

        it 'makes request with correct URL' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/pipelines/456/jobs",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end

        context 'with pagination parameters' do
          let(:arguments) do
            { id: 'test-project', pipeline_id: 456, page: 2, per_page: 50 }
          end

          it 'includes pagination parameters in query' do
            service.execute(oauth_token, arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/pipelines/456/jobs",
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
            { id: 'test-project', pipeline_id: 456, page: 3 }
          end

          it 'includes only page parameter in query' do
            service.execute(oauth_token, arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/pipelines/456/jobs",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'), query: { page: 3 }, verify: false
              )
            )
          end
        end

        context 'with only per_page parameter' do
          let(:arguments) do
            { id: 'test-project', pipeline_id: 456, per_page: 25 }
          end

          it 'includes only per_page parameter in query' do
            service.execute(oauth_token, arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/pipelines/456/jobs",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'), query: { per_page: 25 }, verify: false
              )
            )
          end
        end
      end

      context 'with single job' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) do
          [
            {
              'id' => 123,
              'name' => 'build',
              'stage' => 'build',
              'status' => 'success',
              'web_url' => 'https://gitlab.com/test-project/-/jobs/123'
            }
          ].to_json
        end

        let(:arguments) do
          { id: 'test-project', pipeline_id: 456 }
        end

        it 'returns single job response' do
          result = service.execute(oauth_token, arguments)

          expect(result[:isError]).to be false
          expect(result[:content]).to be_an(Array)
          expect(result[:content].length).to eq(1)
          expect(result[:content].first[:type]).to eq('text')
          expect(result[:content].first[:text]).to include('https://gitlab.com/test-project/-/jobs/123')
        end
      end

      context 'with project ID that needs encoding' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) { [].to_json }
        let(:arguments) do
          { id: 'foo-bar/gitlab', pipeline_id: 789 }
        end

        it 'URL encodes the project ID' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/foo-bar%2Fgitlab/pipelines/789/jobs",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end
      end

      context 'with empty jobs response' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) { [].to_json }
        let(:arguments) do
          { id: 'test-project', pipeline_id: 456 }
        end

        it 'returns success response with empty array' do
          result = service.execute(oauth_token, arguments)
          expect(result[:isError]).to be false
          expect(result[:content]).to match_array([{ text: '', type: 'text' }])
          expect(result[:structuredContent]).to eq({ items: [], metadata: { count: 0, has_more: false } })
        end
      end

      context 'with failed response' do
        let(:success) { false }
        let(:response_code) { 404 }
        let(:response_body) do
          { 'message' => 'Pipeline not found' }.to_json
        end

        let(:arguments) do
          { id: 'test-project', pipeline_id: 999 }
        end

        it 'returns error response' do
          result = service.execute(oauth_token, arguments)

          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to eq('Pipeline not found')
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
        expect(result[:content].first[:text]).to include('pipeline_id is missing')
      end
    end

    context 'with missing project id' do
      let(:arguments) do
        { pipeline_id: 456 }
      end

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('id is missing')
      end
    end
  end
end
