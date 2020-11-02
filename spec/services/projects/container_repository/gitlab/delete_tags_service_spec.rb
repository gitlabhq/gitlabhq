# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::Gitlab::DeleteTagsService do
  include_context 'container repository delete tags service shared context'

  let(:service) { described_class.new(repository, tags) }

  describe '#execute' do
    let(:tags) { %w[A Ba] }

    subject { service.execute }

    before do
      stub_feature_flags(container_registry_expiration_policies_throttling: false)
    end

    RSpec.shared_examples 'deleting tags' do
      it 'deletes the tags by name' do
        stub_delete_reference_requests(tags)
        expect_delete_tag_by_names(tags)

        is_expected.to eq(status: :success, deleted: tags)
      end
    end

    context 'with tags to delete' do
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

          it { is_expected.to eq(status: :error, message: 'could not delete tags') }
        end
      end

      context 'with throttling enabled' do
        let(:timeout) { 10 }

        before do
          stub_feature_flags(container_registry_expiration_policies_throttling: true)
          stub_application_setting(container_registry_delete_tags_service_timeout: timeout)
        end

        it_behaves_like 'deleting tags'

        context 'with timeout' do
          context 'set to a valid value' do
            before do
              allow(Time.zone).to receive(:now).and_return(10, 15, 25) # third call to Time.zone.now will be triggering the timeout
              stub_delete_reference_requests('A' => 200)
            end

            it { is_expected.to eq(status: :error, message: 'timeout while deleting tags', deleted: ['A']) }

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
      end
    end

    context 'with empty tags' do
      let_it_be(:tags) { [] }

      it 'does not remove anything' do
        expect_any_instance_of(ContainerRegistry::Client).not_to receive(:delete_repository_tag_by_name)

        is_expected.to eq(status: :success, deleted: [])
      end
    end
  end
end
