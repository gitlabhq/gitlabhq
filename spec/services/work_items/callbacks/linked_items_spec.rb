# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::LinkedItems, :freeze_time, feature_category: :portfolio_management do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: reporter) }
  let_it_be(:work_ite_to_link) { create(:work_item, project: project) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:error_class) { ::Issuable::Callbacks::Base::Error }
  let(:current_user) { reporter }
  let(:work_items_ids) { [work_ite_to_link.id] }
  let(:params) { { work_items_ids: work_items_ids, link_type: 'relates_to' } }
  let(:service) { described_class.new(issuable: work_item, current_user: current_user, params: params) }

  describe '#after_save_commit' do
    subject(:linked_items_callback) { service.after_save_commit }

    shared_examples 'calls RelatedWorkItemLinks::CreateService service and raises WidgetError' do
      let(:message) do
        'No matching work item found. Make sure you are adding a valid ID and you have access to the item.'
      end

      specify do
        expect(::WorkItems::RelatedWorkItemLinks::CreateService).to receive(:new).and_call_original

        expect { linked_items_callback }.to raise_error(error_class, message)
      end
    end

    it 'links work item' do
      expect(::WorkItems::RelatedWorkItemLinks::CreateService).to receive(:new).and_call_original

      linked_items_callback

      expect(work_item.reload.linked_work_items(authorize: false)).to contain_exactly(work_ite_to_link)
    end

    context 'when param link_type is not present' do
      let(:params) { { work_items_ids: work_items_ids } }

      it 'links work item with default link type' do
        expect(::WorkItems::RelatedWorkItemLinks::CreateService).to receive(:new).and_call_original

        linked_items_callback

        expect(work_item.reload.linked_work_items(authorize: false)).to contain_exactly(work_ite_to_link)
        expect(WorkItems::RelatedWorkItemLink.find_by(source: work_item)&.link_type).to eq('relates_to')
      end
    end

    context 'when user does not have access to the work item' do
      let(:current_user) { create(:user) }

      it 'does not link the work item' do
        expect(::WorkItems::RelatedWorkItemLinks::CreateService).not_to receive(:new)

        linked_items_callback

        expect(work_item.reload.linked_work_items(authorize: false)).to be_empty
      end
    end

    context 'when user does not have access to the work item to link' do
      let_it_be(:work_items_ids) { [create(:work_item, project: create(:project, :private)).id] }

      it_behaves_like 'calls RelatedWorkItemLinks::CreateService service and raises WidgetError'
    end

    context 'when item to link does not exists' do
      let_it_be(:work_items_ids) { [non_existing_record_id] }

      it_behaves_like 'calls RelatedWorkItemLinks::CreateService service and raises WidgetError'
    end
  end
end
