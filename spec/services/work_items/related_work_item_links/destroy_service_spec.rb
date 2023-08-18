# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::RelatedWorkItemLinks::DestroyService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:project) { create(:project_empty_repo, :private) }
    let_it_be(:other_project) { create(:project_empty_repo, :private) }
    let_it_be(:user) { create(:user) }
    let_it_be(:source) { create(:work_item, project: project) }
    let_it_be(:linked_item1) { create(:work_item, project: project) }
    let_it_be(:linked_item2) { create(:work_item, project: project) }
    let_it_be(:no_access_item) { create(:work_item, project: other_project) }
    let_it_be(:not_linked_item) { create(:work_item, project: project) }

    let_it_be(:link1) { create(:work_item_link, source: source, target: linked_item1) }
    let_it_be(:link2) { create(:work_item_link, source: source, target: linked_item2) }
    let_it_be(:link3) { create(:work_item_link, source: source, target: no_access_item) }

    let(:ids_to_remove) { [linked_item1.id, linked_item2.id, no_access_item.id, not_linked_item.id] }

    subject(:destroy_links) { described_class.new(source, user, { item_ids: ids_to_remove }).execute }

    context 'when user can `admin_work_item_link` for the work item' do
      before_all do
        project.add_guest(user)
      end

      it 'removes existing linked items with access' do
        expect { destroy_links }.to change { WorkItems::RelatedWorkItemLink.count }.by(-2)
      end

      it 'creates notes for the source and target of each removed link' do
        [linked_item1, linked_item2].each do |item|
          expect(SystemNoteService).to receive(:unrelate_issuable).with(source, item, user)
          expect(SystemNoteService).to receive(:unrelate_issuable).with(item, source, user)
        end

        destroy_links
      end

      it 'returns correct response message' do
        message = "Successfully unlinked IDs: #{linked_item1.id} and #{linked_item2.id}. IDs with errors: " \
                  "#{no_access_item.id} could not be removed due to insufficient permissions, " \
                  "#{not_linked_item.id} could not be removed due to not being linked."

        is_expected.to eq(
          status: :success,
          message: message,
          items_removed: [linked_item1.id, linked_item2.id],
          items_with_errors: [no_access_item.id]
        )
      end

      context 'when all items fail' do
        let(:ids_to_remove) { [no_access_item.id] }
        let(:params) { { item_ids: [no_access_item.id] } }
        let(:error_msg) { "IDs with errors: #{ids_to_remove[0]} could not be removed due to insufficient permissions." }

        it 'returns an error response' do
          expect { destroy_links }.not_to change { WorkItems::RelatedWorkItemLink.count }

          is_expected.to eq(status: :error, message: error_msg)
        end
      end

      context 'when item_ids is empty' do
        let(:ids_to_remove) { [] }

        it 'returns error response' do
          is_expected.to eq(message: 'No work item IDs provided.', status: :error, http_status: 409)
        end
      end
    end

    context 'when user cannot `admin_work_item_link` for the work item' do
      it 'returns error response' do
        is_expected.to eq(message: 'No work item found.', status: :error, http_status: 403)
      end
    end
  end
end
