# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GetIssueService, feature_category: :mcp_server do
  let(:service) { described_class.new(name: 'get_issue') }

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to eq('Get a single project issue.')
    end
  end

  describe '#input_schema' do
    it 'returns the correct schema' do
      schema = service.input_schema

      expect(schema[:type]).to eq('object')
      expect(schema[:required]).to eq(%w[id iid])
      expect(schema[:properties][:id][:type]).to eq('string')
      expect(schema[:properties][:iid][:type]).to eq('integer')
    end
  end

  describe '#execute' do
    let(:oauth_token) { 'test_token_123' }

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
          {
            'id' => 123,
            'iid' => 5,
            'title' => 'Test Issue',
            'web_url' => 'https://gitlab.com/test-project/issues/5'
          }.to_json
        end

        let(:arguments) { { id: 'test-project', iid: 5 } }

        it 'returns success response' do
          result = service.execute(oauth_token, arguments)

          expect(result).to eq({
            content: [{ type: 'text', text: 'https://gitlab.com/test-project/issues/5' }],
            structuredContent: {
              'id' => 123,
              'iid' => 5,
              'title' => 'Test Issue',
              'web_url' => 'https://gitlab.com/test-project/issues/5'
            },
            isError: false
          })
        end

        it 'makes request with correct URL' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/issues/5",
            anything
          )
        end
      end

      context 'with project ID that needs encoding' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) { {}.to_json }
        let(:arguments) { { id: 'gitlab-org/gitlab', iid: 10 } }

        it 'URL encodes the project ID' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/gitlab-org%2Fgitlab/issues/10",
            anything
          )
        end
      end
    end

    context 'with blank required field' do
      let(:arguments) { { id: '', iid: 10 } }

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('id is invalid')
      end
    end

    context 'with missing required field' do
      let(:arguments) { { id: 'test-project' } }

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('iid is missing')
      end
    end

    context 'with invalid path' do
      let(:arguments) { { id: 'test-group/../admin/test-project', iid: 1 } }

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Validation error: path is invalid')
      end
    end
  end
end
