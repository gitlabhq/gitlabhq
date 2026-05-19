# frozen_string_literal: true

RSpec.shared_context 'container registry client stubs' do
  let(:standard_oci_image_index_response) do
    fixture_path = Rails.root.join('spec/fixtures/container_registry/tag_details_oci_image_index.json')
    Gitlab::Json.safe_parse(File.read(fixture_path))
  end

  let(:standard_linux_amd64_ref)   { standard_oci_image_index_response.dig('image', 'manifest', 'references', 0) }
  let(:standard_linux_arm64_ref)   { standard_oci_image_index_response.dig('image', 'manifest', 'references', 1) }
  let(:standard_windows_amd64_ref) { standard_oci_image_index_response.dig('image', 'manifest', 'references', 2) }
  let(:standard_unknown_arch_ref)  { standard_oci_image_index_response.dig('image', 'manifest', 'references', 3) }
  let(:standard_no_platform_ref)   { standard_oci_image_index_response.dig('image', 'manifest', 'references', 4) }

  let(:standard_oci_image_manifest_response) do
    fixture_path = 'spec/fixtures/container_registry/tag_details_oci_image_manifest.json'
    Gitlab::Json.safe_parse(File.read(Rails.root.join(fixture_path)))
  end

  def stub_container_registry_gitlab_api_support(supported: true)
    allow_next_instance_of(ContainerRegistry::GitlabApiClient) do |client|
      allow(client).to receive(:supports_gitlab_api?).and_return(supported)
      yield client if block_given?
    end
  end

  def stub_container_registry_gitlab_api_repository_details(
    client, path:, size_bytes: 0, sizing: nil, last_published_at: nil)
    expected_params = [path]
    expected_params << { sizing: sizing } if sizing.present?

    allow(client).to receive(:repository_details)
      .with(*expected_params)
      .and_return('size_bytes' => size_bytes, 'last_published_at' => last_published_at)
  end

  def stub_container_registry_tag_details(client, path:, tag:, response:)
    allow(client).to receive(:tag_details)
      .with(path, tag)
      .and_return(response)
  end

  def stub_container_registry_gitlab_api_network_error(client_method: :supports_gitlab_api?)
    allow_next_instance_of(ContainerRegistry::GitlabApiClient) do |client|
      allow(client).to receive(client_method).and_raise(::Faraday::Error, nil, nil)
    end
  end
end
