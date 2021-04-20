# frozen_string_literal: true

RSpec.shared_context 'container repository delete tags service shared context' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :private) }
  let_it_be(:repository) { create(:container_repository, :root, project: project) }

  let(:params) { { tags: tags } }

  before do
    stub_container_registry_config(enabled: true,
                                   api_url: 'http://registry.gitlab',
                                   host_port: 'registry.gitlab')

    stub_container_registry_tags(
      repository: repository.path,
      tags: %w(latest A Ba Bb C D E))
  end

  def stub_delete_reference_request(tag, status = 200)
    stub_request(:delete, "http://registry.gitlab/v2/#{repository.path}/tags/reference/#{tag}")
      .to_return(status: status, body: '')
  end

  def stub_delete_reference_requests(tags)
    tags = Array.wrap(tags).to_h { |tag| [tag, 200] } unless tags.is_a?(Hash)

    tags.each do |tag, status|
      stub_request(:delete, "http://registry.gitlab/v2/#{repository.path}/tags/reference/#{tag}")
      .to_return(status: status, body: '')
    end
  end

  def stub_put_manifest_request(tag, status = 200, headers = { 'docker-content-digest' => 'sha256:dummy' })
    stub_request(:put, "http://registry.gitlab/v2/#{repository.path}/manifests/#{tag}")
      .to_return(status: status, body: '', headers: headers)
  end

  def stub_tag_digest(tag, digest)
    stub_request(:head, "http://registry.gitlab/v2/#{repository.path}/manifests/#{tag}")
      .to_return(status: 200, body: '', headers: { 'docker-content-digest' => digest })
  end

  def stub_digest_config(digest, created_at)
    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:blob)
      .with(repository.path, digest, nil) do
      { 'created' => created_at.to_datetime.rfc3339 }.to_json if created_at
    end
  end

  def stub_upload(digest, success: true)
    content = "{\n  \"config\": {\n  }\n}"
    expect_any_instance_of(ContainerRegistry::Client)
      .to receive(:upload_blob)
      .with(repository.path, content, digest) { double(success?: success ) }
  end

  def expect_delete_tag_by_digest(digest)
    expect_any_instance_of(ContainerRegistry::Client)
      .to receive(:delete_repository_tag_by_digest)
      .with(repository.path, digest) { true }

    expect_any_instance_of(ContainerRegistry::Client)
      .not_to receive(:delete_repository_tag_by_name)
  end

  def expect_delete_tag_by_names(names)
    Array.wrap(names).each do |name|
      expect_any_instance_of(ContainerRegistry::Client)
        .to receive(:delete_repository_tag_by_name)
        .with(repository.path, name) { true }

      expect_any_instance_of(ContainerRegistry::Client)
        .not_to receive(:delete_repository_tag_by_digest)
    end
  end
end
