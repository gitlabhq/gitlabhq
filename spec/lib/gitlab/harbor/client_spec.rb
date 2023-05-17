# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Harbor::Client do
  let_it_be(:harbor_integration) { create(:harbor_integration) }

  subject(:client) { described_class.new(harbor_integration) }

  describe '#initialize' do
    context 'if integration is nil' do
      let(:harbor_integration) { nil }

      it 'raises ConfigError' do
        expect { client }.to raise_error(described_class::ConfigError)
      end
    end

    context 'integration is provided' do
      it 'is initialized successfully' do
        expect { client }.not_to raise_error
      end
    end
  end

  describe '#get_repositories' do
    context 'with valid params' do
      let(:mock_response) do
        [
          {
            "artifact_count": 1,
            "creation_time": "2022-03-13T09:36:43.240Z",
            "id": 1,
            "name": "jihuprivate/busybox",
            "project_id": 4,
            "pull_count": 0,
            "update_time": "2022-03-13T09:36:43.240Z"
          }
        ]
      end

      let(:mock_repositories) do
        {
          body: mock_response,
          total_count: 2
        }
      end

      before do
        stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories")
          .with(
            headers: {
              'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
              'Content-Type': 'application/json'
            })
          .to_return(status: 200, body: mock_response.to_json, headers: { "x-total-count": 2 })
      end

      it 'get repositories' do
        expect(client.get_repositories({}).deep_stringify_keys).to eq(mock_repositories.deep_stringify_keys)
      end
    end

    context 'when harbor project does not exist' do
      before do
        stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories")
          .with(
            headers: {
              'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
              'Content-Type': 'application/json'
            })
            .to_return(status: 404, body: {}.to_json)
      end

      it 'raises Gitlab::Harbor::Client::Error' do
        expect do
          client.get_repositories({})
        end.to raise_error(Gitlab::Harbor::Client::Error, 'request error')
      end
    end

    context 'with invalid response' do
      before do
        stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories")
          .with(
            headers: {
              'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
              'Content-Type': 'application/json'
            })
          .to_return(status: 200, body: '[not json}')
      end

      it 'raises Gitlab::Harbor::Client::Error' do
        expect do
          client.get_repositories({})
        end.to raise_error(Gitlab::Harbor::Client::Error, 'invalid response format')
      end
    end
  end

  describe '#get_artifacts' do
    context 'with valid params' do
      let(:mock_response) do
        [
          {
            "digest": "sha256:661e8e44e5d7290fbd42d0495ab4ff6fdf1ad251a9f358969b3264a22107c14d",
            "icon": "sha256:0048162a053eef4d4ce3fe7518615bef084403614f8bca43b40ae2e762e11e06",
            "id": 1,
            "project_id": 1,
            "pull_time": "0001-01-01T00:00:00.000Z",
            "push_time": "2022-04-23T08:04:08.901Z",
            "repository_id": 1,
            "size": 126745886,
            "tags": [
              {
                "artifact_id": 1,
                "id": 1,
                "immutable": false,
                "name": "2",
                "pull_time": "0001-01-01T00:00:00.000Z",
                "push_time": "2022-04-23T08:04:08.920Z",
                "repository_id": 1,
                "signed": false
              }
            ],
            "type": "IMAGE"
          }
        ]
      end

      let(:mock_artifacts) do
        {
          body: mock_response,
          total_count: 1
        }
      end

      before do
        stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories/test/artifacts")
          .with(
            headers: {
              'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
              'Content-Type': 'application/json'
            })
          .to_return(status: 200, body: mock_response.to_json, headers: { "x-total-count": 1 })
      end

      it 'get artifacts' do
        expect(client.get_artifacts({ repository_name: 'test' })
          .deep_stringify_keys).to eq(mock_artifacts.deep_stringify_keys)
      end
    end

    context 'when harbor repository does not exist' do
      before do
        stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories/test/artifacts")
          .with(
            headers: {
              'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
              'Content-Type': 'application/json'
            })
            .to_return(status: 404, body: {}.to_json)
      end

      it 'raises Gitlab::Harbor::Client::Error' do
        expect do
          client.get_artifacts({ repository_name: 'test' })
        end.to raise_error(Gitlab::Harbor::Client::Error, 'request error')
      end
    end

    context 'with invalid response' do
      before do
        stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories/test/artifacts")
          .with(
            headers: {
              'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
              'Content-Type': 'application/json'
            })
          .to_return(status: 200, body: '[not json}')
      end

      it 'raises Gitlab::Harbor::Client::Error' do
        expect do
          client.get_artifacts({ repository_name: 'test' })
        end.to raise_error(Gitlab::Harbor::Client::Error, 'invalid response format')
      end
    end
  end

  describe '#get_tags' do
    context 'with valid params' do
      let(:mock_response) do
        [
          {
            "artifact_id": 1,
            "id": 1,
            "immutable": false,
            "name": "2",
            "pull_time": "0001-01-01T00:00:00.000Z",
            "push_time": "2022-04-23T08:04:08.920Z",
            "repository_id": 1,
            "signed": false
          }
        ]
      end

      let(:mock_tags) do
        {
          body: mock_response,
          total_count: 1
        }
      end

      before do
        stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories/test/artifacts/1/tags")
          .with(
            headers: {
              'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
              'Content-Type': 'application/json'
            })
          .to_return(status: 200, body: mock_response.to_json, headers: { "x-total-count": 1 })
      end

      it 'get tags' do
        expect(client.get_tags({ repository_name: 'test', artifact_name: '1' })
          .deep_stringify_keys).to eq(mock_tags.deep_stringify_keys)
      end
    end

    context 'when harbor artifact does not exist' do
      before do
        stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories/test/artifacts/1/tags")
          .with(
            headers: {
              'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
              'Content-Type': 'application/json'
            })
            .to_return(status: 404, body: {}.to_json)
      end

      it 'raises Gitlab::Harbor::Client::Error' do
        expect do
          client.get_tags({ repository_name: 'test', artifact_name: '1' })
        end.to raise_error(Gitlab::Harbor::Client::Error, 'request error')
      end
    end

    context 'with invalid response' do
      before do
        stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories/test/artifacts/1/tags")
          .with(
            headers: {
              'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
              'Content-Type': 'application/json'
            })
          .to_return(status: 200, body: '[not json}')
      end

      it 'raises Gitlab::Harbor::Client::Error' do
        expect do
          client.get_tags({ repository_name: 'test', artifact_name: '1' })
        end.to raise_error(Gitlab::Harbor::Client::Error, 'invalid response format')
      end
    end
  end

  describe '#check_project_availability' do
    before do
      stub_request(:head, "https://demo.goharbor.io/api/v2.0/projects?project_name=testproject")
        .with(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
            'Content-Type': 'application/json'
          })
        .to_return(status: 200, body: '', headers: {})
    end

    it "calls api/v2.0/projects successfully" do
      expect(client.check_project_availability).to eq(success: true)
    end
  end

  private

  def stub_harbor_request(url, body: {}, status: 200, headers: {})
    stub_request(:get, url)
      .to_return(
        status: status,
        headers: { 'Content-Type' => 'application/json' }.merge(headers),
        body: body.to_json
      )
  end
end
