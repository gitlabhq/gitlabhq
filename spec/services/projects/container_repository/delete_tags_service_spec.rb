# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::DeleteTagsService, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax
  include_context 'container repository delete tags service shared context'

  let(:service) { described_class.new(project, user, params) }

  let_it_be(:available_service_classes) do
    [
      ::Projects::ContainerRepository::Gitlab::DeleteTagsService,
      ::Projects::ContainerRepository::ThirdParty::DeleteTagsService
    ]
  end

  shared_examples 'logging a success response' do
    it 'logs an info message' do
      expect(service).to receive(:log_info).with(
        {
          service_class: 'Projects::ContainerRepository::DeleteTagsService',
          message: 'deleted tags',
          container_repository_id: repository.id,
          project_id: repository.project_id,
          deleted_tags_count: tags.size
        }
      )

      subject
    end
  end

  shared_examples 'logging an error response' do |message: 'could not delete tags', extra_log: {}|
    it 'logs an error message' do
      log_data = {
          service_class: 'Projects::ContainerRepository::DeleteTagsService',
          message: message,
          container_repository_id: repository.id,
          project_id: repository.project_id
      }

      log_data.merge!(extra_log) if extra_log.any?

      expect(service).to receive(:log_error).with(log_data)

      subject
    end
  end

  shared_examples 'calling the correct delete tags service' do |expected_service_class|
    let(:service_response) { { status: :success, deleted: tags } }
    let(:excluded_service_class) { available_service_classes.excluding(expected_service_class).first }

    before do
      service_double = double
      expect(expected_service_class).to receive(:new).with(repository, tags).and_return(service_double)
      expect(excluded_service_class).not_to receive(:new)
      expect(service_double).to receive(:execute).and_return(service_response)
    end

    it { is_expected.to include(status: :success) }

    it_behaves_like 'logging a success response'

    context 'with an error service response' do
      let(:service_response) { { status: :error, message: 'could not delete tags' } }

      it { is_expected.to include(status: :error) }

      it_behaves_like 'logging an error response'
    end
  end

  shared_examples 'handling invalid params' do
    context 'with invalid params' do
      before do
        expect(::Projects::ContainerRepository::Gitlab::DeleteTagsService).not_to receive(:new)
        expect(::Projects::ContainerRepository::ThirdParty::DeleteTagsService).not_to receive(:new)
        expect_any_instance_of(ContainerRegistry::Client).not_to receive(:delete_repository_tag_by_digest)
      end

      context 'when no params are specified' do
        let_it_be(:params) { {} }

        it { is_expected.to include(status: :error) }
      end

      context 'with empty tags' do
        let_it_be(:tags) { [] }

        it { is_expected.to include(status: :error) }
      end
    end
  end

  shared_examples 'supporting fast delete' do
    context 'when the registry supports fast delete' do
      before do
        allow(repository.client).to receive(:supports_tag_delete?).and_return(true)
      end

      it_behaves_like 'calling the correct delete tags service', ::Projects::ContainerRepository::Gitlab::DeleteTagsService

      it_behaves_like 'handling invalid params'

      context 'with the real service' do
        before do
          stub_delete_reference_requests(tags)
          expect_delete_tags(tags)
        end

        it { is_expected.to include(status: :success) }

        it_behaves_like 'logging a success response'
      end

      context 'with a timeout error' do
        before do
          expect_next_instance_of(::Projects::ContainerRepository::Gitlab::DeleteTagsService) do |delete_service|
            expect(delete_service).to receive(:delete_tags).and_raise(::Projects::ContainerRepository::Gitlab::DeleteTagsService::TimeoutError)
          end
        end

        it { is_expected.to include(status: :error, message: 'error while deleting tags') }

        it_behaves_like 'logging an error response', message: 'error while deleting tags', extra_log: { deleted_tags_count: 0 }
      end
    end
  end

  describe '#execute' do
    let(:tags) { %w[A Ba] }

    subject { service.execute(repository) }

    context 'without permissions' do
      it { is_expected.to include(status: :error) }
    end

    context 'with permissions' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'supporting fast delete'

      context 'when the registry does not support fast delete' do
        before do
          allow(repository.client).to receive(:supports_tag_delete?).and_return(false)
        end

        it_behaves_like 'calling the correct delete tags service', ::Projects::ContainerRepository::ThirdParty::DeleteTagsService

        it_behaves_like 'handling invalid params'
      end
    end

    context 'without user' do
      let_it_be(:user) { nil }

      context 'when not run by a cleanup policy' do
        it { is_expected.to include(status: :error) }
      end

      context 'when run by a cleanup policy' do
        let(:params) { { tags: tags, container_expiration_policy: true } }

        it_behaves_like 'supporting fast delete'
      end
    end
  end
end
