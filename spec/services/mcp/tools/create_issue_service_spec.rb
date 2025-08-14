# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::CreateIssueService, feature_category: :mcp_server do
  let(:service) { described_class.new(name: 'create_issue') }

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to eq('Create a new project issue.')
    end
  end

  describe '#input_schema' do
    it 'returns the correct schema' do
      schema = service.input_schema

      expect(schema[:type]).to eq('object')
      expect(schema[:required]).to eq(%w[id title])
      expect(schema[:properties][:id][:type]).to eq('string')
      expect(schema[:properties][:title][:type]).to eq('string')
      expect(schema[:properties][:description][:type]).to eq('string')
      expect(schema[:properties][:assignee_ids][:type]).to eq('array')
      expect(schema[:properties][:confidential][:default]).to be false
    end
  end

  describe '#execute' do
    let(:oauth_token) { 'test_token_123' }

    context 'with valid arguments' do
      let(:api_response) do
        instance_double(Gitlab::HTTP::Response, body: response_body, success?: success, code: response_code)
      end

      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(api_response)
      end

      context 'with successful response' do
        let(:success) { true }
        let(:response_code) { 201 }
        let(:response_body) do
          {
            'id' => 456,
            'iid' => 15,
            'title' => 'New Issue',
            'web_url' => 'https://gitlab.com/test-project/issues/15'
          }.to_json
        end

        let(:arguments) do
          {
            id: 'test-project',
            title: 'New Issue',
            description: 'Issue description',
            labels: 'bug,urgent'
          }
        end

        it 'returns success response' do
          result = service.execute(oauth_token, arguments)

          expect(result).to eq({
            content: [{ type: 'text', text: 'https://gitlab.com/test-project/issues/15' }],
            structuredContent: {
              'id' => 456,
              'iid' => 15,
              'title' => 'New Issue',
              'web_url' => 'https://gitlab.com/test-project/issues/15'
            },
            isError: false
          })
        end

        it 'makes POST request with correct body' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:post).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/issues",
            hash_including(
              body: {
                title: 'New Issue',
                description: 'Issue description',
                labels: 'bug,urgent'
              }.to_json
            )
          )
        end
      end

      context 'with project ID that needs encoding' do
        let(:success) { true }
        let(:response_code) { 201 }
        let(:response_body) { {}.to_json }
        let(:arguments) { { id: 'gitlab-org/gitlab', title: 'Test' } }

        it 'URL encodes the project ID' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:post).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/gitlab-org%2Fgitlab/issues", anything
          )
        end
      end

      context 'with all optional fields' do
        let(:success) { true }
        let(:response_code) { 201 }
        let(:response_body) { {}.to_json }
        let(:arguments) do
          {
            id: 'project-1',
            title: 'Full Issue',
            description: 'Description',
            assignee_ids: [1, 2],
            milestone_id: 10,
            epic_id: 5,
            labels: 'bug',
            confidential: true
          }
        end

        it 'sends all fields except id in body' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:post).with(
            anything,
            hash_including(
              body: {
                title: 'Full Issue',
                description: 'Description',
                assignee_ids: [1, 2],
                milestone_id: 10,
                epic_id: 5,
                labels: 'bug',
                confidential: true
              }.to_json
            )
          )
        end
      end
    end

    context 'with missing required field' do
      let(:arguments) { { id: 'test-project' } }

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('title is missing')
      end
    end

    context 'with blank required field' do
      let(:arguments) { { id: '', title: 'Test' } }

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('id is invalid')
      end
    end

    context 'with invalid title length' do
      let(:arguments) { { id: 'test-project', title: '' } }

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('title is invalid')
      end
    end

    context 'with invalid path' do
      let(:arguments) { { id: 'test-group/../admin/test-project', title: 'test issue' } }

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Validation error: path is invalid')
      end
    end
  end
end
