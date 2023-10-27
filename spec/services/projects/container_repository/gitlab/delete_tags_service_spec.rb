# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::Gitlab::DeleteTagsService, feature_category: :container_registry do
  include_context 'container repository delete tags service shared context'

  let(:service) { described_class.new(repository, tags) }

  describe '#execute' do
    let(:tags) { %w[A Ba] }

    subject { service.execute }

    RSpec.shared_examples 'deleting tags' do
      it 'deletes the tags by name' do
        stub_delete_reference_requests(tags)
        expect_delete_tags(tags)

        is_expected.to eq(status: :success, deleted: tags)
      end
    end

    context 'with tags to delete' do
      let(:timeout) { 10 }

      before do
        stub_application_setting(container_registry_delete_tags_service_timeout: timeout)
      end

      it_behaves_like 'deleting tags'

      it 'succeeds when tag delete returns 404' do
        stub_delete_reference_requests('A' => 200, 'Ba' => 404)

        is_expected.to eq(status: :success, deleted: tags)
      end

      it 'succeeds when a tag delete returns 500' do
        stub_delete_reference_requests('A' => 200, 'Ba' => 500)

        is_expected.to eq(status: :success, deleted: ['A'])
      end

      context 'with failures' do
        context 'when the delete request fails' do
          before do
            stub_delete_reference_requests('A' => 500, 'Ba' => 500)
          end

          it { is_expected.to eq(status: :error, message: "could not delete tags: #{tags.join(', ')}") }

          context 'when a large list of tag delete fails' do
            let(:tags) { Array.new(135) { |i| "tag#{i}" } }
            let(:container_repository) { instance_double(ContainerRepository) }

            before do
              allow(ContainerRepository).to receive(:find).with(repository).and_return(container_repository)
              tags.each do |tag|
                stub_delete_reference_requests(tag => 500)
              end
              allow(container_repository).to receive(:delete_tag).and_return(false)
            end

            it 'truncates the log message' do
              expect(subject).to eq(status: :error, message: "could not delete tags: #{tags.join(', ')}".truncate(1000))
            end
          end
        end
      end

      context 'with timeout' do
        context 'set to a valid value' do
          before do
            allow(service).to receive(:timeout?).and_return(false, true)
            stub_delete_reference_requests('A' => 200)
          end

          it { is_expected.to eq(status: :error, message: 'error while deleting tags', deleted: ['A'], exception_class_name: Projects::ContainerRepository::Gitlab::DeleteTagsService::TimeoutError.name) }

          it 'tracks the exception' do
            expect(::Gitlab::ErrorTracking)
              .to receive(:track_exception).with(::Projects::ContainerRepository::Gitlab::DeleteTagsService::TimeoutError, tags_count: tags.size, container_repository_id: repository.id)

            subject
          end
        end

        context 'set to 0' do
          let(:timeout) { 0 }

          it_behaves_like 'deleting tags'
        end

        context 'set to nil' do
          let(:timeout) { nil }

          it_behaves_like 'deleting tags'
        end
      end

      context 'with a network error' do
        before do
          expect(service).to receive(:delete_tags).and_raise(::Faraday::TimeoutError)
        end

        it { is_expected.to eq(status: :error, message: 'error while deleting tags', deleted: [], exception_class_name: ::Faraday::TimeoutError.name) }

        it 'tracks the exception' do
          expect(::Gitlab::ErrorTracking)
            .to receive(:track_exception).with(::Faraday::TimeoutError, tags_count: tags.size, container_repository_id: repository.id)

          subject
        end
      end
    end

    context 'with empty tags' do
      let_it_be(:tags) { [] }

      it 'does not remove anything' do
        expect_any_instance_of(ContainerRegistry::Client).not_to receive(:delete_repository_tag_by_digest)

        is_expected.to eq(status: :success, deleted: [])
      end
    end
  end
end
