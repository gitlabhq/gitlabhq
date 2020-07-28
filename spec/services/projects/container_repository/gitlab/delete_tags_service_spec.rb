# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::Gitlab::DeleteTagsService do
  include_context 'container repository delete tags service shared context'

  let(:service) { described_class.new(repository, tags) }

  describe '#execute' do
    let(:tags) { %w[A Ba] }

    subject { service.execute }

    context 'with tags to delete' do
      it 'deletes the tags by name' do
        stub_delete_reference_requests(tags)
        expect_delete_tag_by_names(tags)

        is_expected.to eq(status: :success, deleted: tags)
      end

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
