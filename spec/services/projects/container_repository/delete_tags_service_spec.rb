# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::DeleteTagsService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:repository) { create(:container_repository, :root, project: project) }

  let(:params) { { tags: tags } }
  let(:service) { described_class.new(project, user, params) }

  before do
    stub_container_registry_config(enabled: true,
                                   api_url: 'http://registry.gitlab',
                                   host_port: 'registry.gitlab')

    stub_container_registry_tags(
      repository: repository.path,
      tags: %w(latest A Ba Bb C D E))
  end

  RSpec.shared_examples 'logging a success response' do
    it 'logs an info message' do
      expect(service).to receive(:log_info).with(
        service_class: 'Projects::ContainerRepository::DeleteTagsService',
        message: 'deleted tags',
        container_repository_id: repository.id,
        deleted_tags_count: tags.size
      )

      subject
    end
  end

  RSpec.shared_examples 'logging an error response' do |message: 'could not delete tags'|
    it 'logs an error message' do
      expect(service).to receive(:log_error).with(
        service_class: 'Projects::ContainerRepository::DeleteTagsService',
        message: message,
        container_repository_id: repository.id
      )

      subject
    end
  end

  describe '#execute' do
    let(:tags) { %w[A] }

    subject { service.execute(repository) }

    context 'without permissions' do
      it { is_expected.to include(status: :error) }
    end

    context 'with permissions' do
      before do
        project.add_developer(user)
      end

      context 'when the registry supports fast delete' do
        context 'and the feature is enabled' do
          let_it_be(:project) { create(:project, :private) }
          let_it_be(:repository) { create(:container_repository, :root, project: project) }

          before do
            allow(repository.client).to receive(:supports_tag_delete?).and_return(true)
          end

          context 'with tags to delete' do
            let_it_be(:tags) { %w[A Ba] }

            it 'deletes the tags by name' do
              stub_delete_reference_request('A')
              stub_delete_reference_request('Ba')

              expect_delete_tag_by_name('A')
              expect_delete_tag_by_name('Ba')

              is_expected.to include(status: :success)
            end

            it 'succeeds when tag delete returns 404' do
              stub_delete_reference_request('A')
              stub_delete_reference_request('Ba', 404)

              is_expected.to include(status: :success)
            end

            it_behaves_like 'logging a success response' do
              before do
                stub_delete_reference_request('A')
                stub_delete_reference_request('Ba')
              end
            end

            context 'with failures' do
              context 'when the delete request fails' do
                before do
                  stub_delete_reference_request('A', 500)
                  stub_delete_reference_request('Ba', 500)
                end

                it { is_expected.to include(status: :error) }

                it_behaves_like 'logging an error response'
              end
            end
          end

          context 'when no params are specified' do
            let_it_be(:params) { {} }

            it 'does not remove anything' do
              expect_any_instance_of(ContainerRegistry::Client).not_to receive(:delete_repository_tag_by_name)

              is_expected.to include(status: :error)
            end
          end

          context 'with empty tags' do
            let_it_be(:tags) { [] }

            it 'does not remove anything' do
              expect_any_instance_of(ContainerRegistry::Client).not_to receive(:delete_repository_tag_by_name)

              is_expected.to include(status: :error)
            end
          end
        end

        context 'and the feature is disabled' do
          let_it_be(:tags) { %w[A Ba] }

          before do
            stub_feature_flags(container_registry_fast_tag_delete: false)
            stub_upload("{\n  \"config\": {\n  }\n}", 'sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3')
            stub_put_manifest_request('A')
            stub_put_manifest_request('Ba')
          end

          it 'fallbacks to slow delete' do
            expect(service).not_to receive(:fast_delete)
            expect(service).to receive(:slow_delete).with(repository, tags).and_call_original

            expect_delete_tag_by_digest('sha256:dummy')

            subject
          end

          it_behaves_like 'logging a success response' do
            before do
              allow(service).to receive(:slow_delete).and_call_original
              expect_delete_tag_by_digest('sha256:dummy')
            end
          end
        end
      end

      context 'when the registry does not support fast delete' do
        let_it_be(:project) { create(:project, :private) }
        let_it_be(:repository) { create(:container_repository, :root, project: project) }

        before do
          stub_tag_digest('latest', 'sha256:configA')
          stub_tag_digest('A', 'sha256:configA')
          stub_tag_digest('Ba', 'sha256:configB')

          allow(repository.client).to receive(:supports_tag_delete?).and_return(false)
        end

        context 'when no params are specified' do
          let_it_be(:params) { {} }

          it 'does not remove anything' do
            expect_any_instance_of(ContainerRegistry::Client).not_to receive(:delete_repository_tag_by_digest)

            is_expected.to include(status: :error)
          end
        end

        context 'with empty tags' do
          let_it_be(:tags) { [] }

          it 'does not remove anything' do
            expect_any_instance_of(ContainerRegistry::Client).not_to receive(:delete_repository_tag_by_digest)

            is_expected.to include(status: :error)
          end
        end

        context 'with tags to delete' do
          let_it_be(:tags) { %w[A Ba] }

          it 'deletes the tags using a dummy image' do
            stub_upload("{\n  \"config\": {\n  }\n}", 'sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3')

            stub_put_manifest_request('A')
            stub_put_manifest_request('Ba')

            expect_delete_tag_by_digest('sha256:dummy')

            is_expected.to include(status: :success)
          end

          it 'succeeds when tag delete returns 404' do
            stub_upload("{\n  \"config\": {\n  }\n}", 'sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3')

            stub_put_manifest_request('A')
            stub_put_manifest_request('Ba')

            stub_request(:delete, "http://registry.gitlab/v2/#{repository.path}/manifests/sha256:dummy")
              .to_return(status: 404, body: "", headers: {})

            is_expected.to include(status: :success)
          end

          it_behaves_like 'logging a success response' do
            before do
              stub_upload("{\n  \"config\": {\n  }\n}", 'sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3')
              stub_put_manifest_request('A')
              stub_put_manifest_request('Ba')
              expect_delete_tag_by_digest('sha256:dummy')
            end
          end

          context 'with failures' do
            context 'when the dummy manifest generation fails' do
              before do
                stub_upload("{\n  \"config\": {\n  }\n}", 'sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3', success: false)
              end

              it { is_expected.to include(status: :error) }

              it_behaves_like 'logging an error response', message: 'could not generate manifest'
            end

            context 'when updating the tags fails' do
              before do
                stub_upload("{\n  \"config\": {\n  }\n}", 'sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3')

                stub_put_manifest_request('A', 500)
                stub_put_manifest_request('Ba', 500)

                stub_request(:delete, "http://registry.gitlab/v2/#{repository.path}/manifests/sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3")
                  .to_return(status: 200, body: "", headers: {})
              end

              it { is_expected.to include(status: :error) }
              it_behaves_like 'logging an error response'
            end
          end
        end
      end
    end
  end

  private

  def stub_delete_reference_request(tag, status = 200)
    stub_request(:delete, "http://registry.gitlab/v2/#{repository.path}/tags/reference/#{tag}")
      .to_return(status: status, body: '')
  end

  def stub_put_manifest_request(tag, status = 200, headers = { 'docker-content-digest' => 'sha256:dummy' })
    stub_request(:put, "http://registry.gitlab/v2/#{repository.path}/manifests/#{tag}")
      .to_return(status: status, body: '', headers: headers)
  end

  def stub_tag_digest(tag, digest)
    stub_request(:head, "http://registry.gitlab/v2/#{repository.path}/manifests/#{tag}")
      .to_return(status: 200, body: "", headers: { 'docker-content-digest' => digest })
  end

  def stub_digest_config(digest, created_at)
    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:blob)
      .with(repository.path, digest, nil) do
      { 'created' => created_at.to_datetime.rfc3339 }.to_json if created_at
    end
  end

  def stub_upload(content, digest, success: true)
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

  def expect_delete_tag_by_name(name)
    expect_any_instance_of(ContainerRegistry::Client)
      .to receive(:delete_repository_tag_by_name)
      .with(repository.path, name) { true }

    expect_any_instance_of(ContainerRegistry::Client)
      .not_to receive(:delete_repository_tag_by_digest)
  end
end
