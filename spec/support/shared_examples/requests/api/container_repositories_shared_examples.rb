# frozen_string_literal: true

RSpec.shared_examples 'rejected container repository access' do |user_type, status, body_message = nil|
  context "for #{user_type}" do
    let(:api_user) { users[user_type] }

    it "returns #{status}" do
      subject

      expect(response).to have_gitlab_http_status(status)

      expect(Gitlab::Json.parse(response.body)['message']).to eq(body_message) if body_message
    end
  end
end

RSpec.shared_examples 'returns repositories for allowed users' do |user_type, scope|
  context "for #{user_type}" do
    it 'returns a list of repositories' do
      subject

      expect(json_response.length).to eq(2)
      expect(json_response.pluck('id')).to contain_exactly(
        root_repository.id, test_repository.id)
      expect(response.body).not_to include('tags')
      expect(response.body).not_to include('tags_count')
    end

    it 'returns a matching schema' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('registry/repositories')
    end
  end
end

RSpec.shared_examples 'returns tags for allowed users' do |user_type, scope|
  context "for #{user_type}" do
    context 'with tags param' do
      let(:url) { "/#{scope}s/#{object.id}/registry/repositories?tags=true" }

      before do
        stub_container_registry_tags(repository: root_repository.path, tags: %w[rootA latest], with_manifest: true)
        stub_container_registry_tags(repository: test_repository.path, tags: %w[rootA latest], with_manifest: true)
      end

      it 'returns a list of repositories and their tags' do
        subject

        expect(json_response.length).to eq(2)
        expect(json_response.pluck('id')).to contain_exactly(
          root_repository.id, test_repository.id)
        expect(response.body).to include('tags')
      end

      it 'returns a matching schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('registry/repositories')
      end
    end

    context 'with tags_count param' do
      let(:url) { "/#{scope}s/#{object.id}/registry/repositories?tags_count=true" }

      before do
        stub_container_registry_tags(repository: root_repository.path, tags: %w[rootA latest], with_manifest: true)
        stub_container_registry_tags(repository: test_repository.path, tags: %w[rootA latest], with_manifest: true)
      end

      it 'returns a list of repositories and their tags_count' do
        subject

        expect(response.body).to include('tags_count')
        expect(json_response[0]['tags_count']).to eq(2)
      end

      it 'returns a matching schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('registry/repositories')
      end
    end
  end
end

RSpec.shared_examples 'handling network errors with the container registry' do
  before do
    stub_container_registry_network_error(client_method: :repository_tags)
  end

  it 'returns a connection error' do
    subject

    expect(response).to have_gitlab_http_status(:service_unavailable)
    expect(json_response['message']).to include('We are having trouble connecting to the Container Registry')
  end
end

RSpec.shared_examples 'handling graphql network errors with the container registry' do
  before do
    stub_container_registry_network_error(client_method: :repository_tags)
  end

  it 'returns a connection error' do
    subject

    expect_graphql_errors_to_include('We are having trouble connecting to the Container Registry')
  end
end

RSpec.shared_examples 'not hitting graphql network errors with the container registry' do
  before do
    stub_container_registry_network_error(client_method: :repository_tags)
  end

  it 'does not return any error' do
    subject

    expect_graphql_errors_to_be_empty
  end
end
