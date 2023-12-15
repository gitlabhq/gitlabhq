# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GoogleCloudPlatform::ArtifactRegistry::Client, feature_category: :container_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }
  let_it_be(:rsa_key_data) { rsa_key.to_s }

  let(:gcp_project_id) { 'gcp_project_id' }
  let(:gcp_location) { 'gcp_location' }
  let(:gcp_repository) { 'gcp_repository' }
  let(:gcp_wlif) { 'https://wlif.test' }

  let(:user) { project.owner }
  let(:client) do
    described_class.new(
      project: project,
      user: user,
      gcp_project_id: gcp_project_id,
      gcp_location: gcp_location,
      gcp_repository: gcp_repository,
      gcp_wlif: gcp_wlif
    )
  end

  describe '#list_docker_images' do
    let(:page_token) { nil }

    subject(:list) { client.list_docker_images(page_token: page_token) }

    before do
      stub_application_setting(ci_jwt_signing_key: rsa_key_data)
    end

    it 'calls glgo list docker images API endpoint' do
      stub_list_docker_image(body: dummy_list_body)
      expect(client).to receive(:encoded_jwt).with(wlif: gcp_wlif)

      expect(list).to include(images: an_instance_of(Array), next_page_token: an_instance_of(String))
    end

    context 'with a page token set' do
      let(:page_token) { 'token' }

      it 'calls glgo list docker images API endpoint with a page token' do
        stub_list_docker_image(body: dummy_list_body, page_token: page_token)

        expect(list).to include(images: an_instance_of(Array), next_page_token: an_instance_of(String))
      end
    end

    context 'with an erroneous response' do
      it 'returns an empty hash' do
        stub_list_docker_image(body: dummy_list_body, status_code: 400)

        expect(list).to eq({})
      end
    end

    private

    def stub_list_docker_image(body:, page_token: nil, status_code: 200)
      url = "#{described_class::GLGO_BASE_URL}/gcp/ar"
      url << "/projects/#{gcp_project_id}"
      url << "/locations/#{gcp_location}"
      url << "/repositories/#{gcp_repository}/docker"
      url << "?page_size=#{described_class::PAGE_SIZE}"
      url << "&page_token=#{page_token}" if page_token.present?

      stub_request(:get, url)
        .to_return(status: status_code, body: body)
    end

    def dummy_list_body
      <<-BODY
        {
          "images": [
            {
              "built_at": "2023-11-30T23:23:11.980068941Z",
              "media_type": "application/vnd.docker.distribution.manifest.v2+json",
              "name": "projects/project/locations/location/repositories/repo/dockerImages/image@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5",
              "size_bytes": 2827903,
              "tags": [
                "tag1",
                "tag2"
              ],
              "updated_at": "2023-12-07T11:48:50.840751Z",
              "uploaded_at": "2023-12-07T11:48:47.598511Z",
              "uri": "location.pkg.dev/project/repo/image@sha256:6a0657acfef760bd9e293361c9b558e98e7d740ed0dffca823d17098a4ffddf5"
            }
          ],
          "next_page_token": "next_page_token"
        }
      BODY
    end
  end
end
