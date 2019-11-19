# frozen_string_literal: true

shared_examples 'rejected container repository access' do |user_type, status|
  context "for #{user_type}" do
    let(:api_user) { users[user_type] }

    it "returns #{status}" do
      subject

      expect(response).to have_gitlab_http_status(status)
    end
  end
end

shared_examples 'returns repositories for allowed users' do |user_type, scope|
  context "for #{user_type}" do
    it 'returns a list of repositories' do
      subject

      expect(json_response.length).to eq(2)
      expect(json_response.map { |repository| repository['id'] }).to contain_exactly(
        root_repository.id, test_repository.id)
      expect(response.body).not_to include('tags')
    end

    it 'returns a matching schema' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('registry/repositories')
    end

    context 'with tags param' do
      let(:url) { "/#{scope}s/#{object.id}/registry/repositories?tags=true" }

      before do
        stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA latest), with_manifest: true)
        stub_container_registry_tags(repository: test_repository.path, tags: %w(rootA latest), with_manifest: true)
      end

      it 'returns a list of repositories and their tags' do
        subject

        expect(json_response.length).to eq(2)
        expect(json_response.map { |repository| repository['id'] }).to contain_exactly(
          root_repository.id, test_repository.id)
        expect(response.body).to include('tags')
      end

      it 'returns a matching schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('registry/repositories')
      end
    end
  end
end

shared_examples 'a gitlab tracking event' do |category, action|
  it "creates a gitlab tracking event #{action}" do
    expect(Gitlab::Tracking).to receive(:event).with(category, action, {})

    subject
  end
end
