# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GetMergeRequestCommitsService, feature_category: :mcp_server do
  let(:service) { described_class.new(name: 'get_merge_request_commits') }

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to eq('Get all commits associated with a merge request.')
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

    before do
      service.set_cred(access_token: oauth_token, current_user: nil)
    end

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
              'id' => 'abc123def456',
              'short_id' => 'abc123d',
              'title' => 'Add new feature',
              'message' => 'Add new feature\n\nThis commit adds a new feature to the application.',
              'author_name' => 'John Doe',
              'author_email' => 'john@example.com',
              'authored_date' => '2024-01-15T10:30:00.000+00:00',
              'committer_name' => 'John Doe',
              'committer_email' => 'john@example.com',
              'committed_date' => '2024-01-15T10:30:00.000+00:00',
              'web_url' => 'https://gitlab.com/test-project/-/commit/abc123def456'
            },
            {
              'id' => 'def456ghi789',
              'short_id' => 'def456g',
              'title' => 'Fix bug in validation',
              'message' => 'Fix bug in validation',
              'author_name' => 'Jane Smith',
              'author_email' => 'jane@example.com',
              'authored_date' => '2024-01-16T14:20:00.000+00:00',
              'committer_name' => 'Jane Smith',
              'committer_email' => 'jane@example.com',
              'committed_date' => '2024-01-16T14:20:00.000+00:00',
              'web_url' => 'https://gitlab.com/test-project/-/commit/def456ghi789'
            }
          ].to_json
        end

        let(:arguments) do
          { arguments: { id: 'test-project', merge_request_iid: 10 } }
        end

        it 'returns success response' do
          result = service.execute(request: nil, params: arguments)
          expect(result[:isError]).to be false
          expect(result[:content].first[:type]).to eq('text')
          expect(result[:content].first[:text]).to include('abc123def456')
          expect(result[:content].first[:text]).to include('def456ghi789')
          expect(result[:structuredContent][:items].length).to eq(2)
          expect(result[:structuredContent][:metadata][:count]).to eq(2)
          expect(result[:structuredContent][:metadata][:has_more]).to be false
          expect(result[:structuredContent][:items].first['id']).to eq('abc123def456')
          expect(result[:structuredContent][:items].first['title']).to eq('Add new feature')
          expect(result[:structuredContent][:items].second['id']).to eq('def456ghi789')
          expect(result[:structuredContent][:items].second['title']).to eq('Fix bug in validation')
        end

        it 'makes request with correct URL' do
          service.execute(request: nil, params: arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/commits",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end

        context 'with pagination parameters' do
          let(:arguments) do
            { arguments: { id: 'test-project', merge_request_iid: 10, page: 2, per_page: 50 } }
          end

          it 'includes pagination parameters in query' do
            service.execute(request: nil, params: arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/commits",
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
            { arguments: { id: 'test-project', merge_request_iid: 10, page: 3 } }
          end

          it 'includes only page parameter in query' do
            service.execute(request: nil, params: arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/commits",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'), query: { page: 3 }, verify: false
              )
            )
          end
        end

        context 'with only per_page parameter' do
          let(:arguments) do
            { arguments: { id: 'test-project', merge_request_iid: 10, per_page: 25 } }
          end

          it 'includes only per_page parameter in query' do
            service.execute(request: nil, params: arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/commits",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'), query: { per_page: 25 }, verify: false
              )
            )
          end
        end
      end

      context 'with project ID that needs encoding' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) { [].to_json }
        let(:arguments) do
          { arguments: { id: 'foo-bar/gitlab', merge_request_iid: 1 } }
        end

        it 'URL encodes the project ID' do
          service.execute(request: nil, params: arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/foo-bar%2Fgitlab/merge_requests/1/commits",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end
      end

      context 'with empty commits response' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) { [].to_json }
        let(:arguments) do
          { arguments: { id: 'test-project', merge_request_iid: 10 } }
        end

        it 'returns success response with empty array' do
          result = service.execute(request: nil, params: arguments)

          expect(result[:isError]).to be false
          expect(result[:content]).to match_array([{ type: 'text', text: '' }])
          expect(result[:structuredContent]).to eq({ items: [], metadata: { count: 0, has_more: false } })
        end
      end
    end

    context 'with missing required field' do
      let(:arguments) do
        { arguments: { id: 'test-project' } }
      end

      it 'returns validation error' do
        result = service.execute(request: nil, params: arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('merge_request_iid is missing')
      end
    end
  end
end
