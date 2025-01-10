# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CreateFromTaskService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:list_work_item, refind: true) do
    create(:work_item, project: project, description: "- [ ] Item to be converted\n    second line\n    third line")
  end

  let(:work_item_to_update) { list_work_item }
  let(:link_params) { {} }
  let(:current_user) { developer }
  let(:task_type) { WorkItems::Type.default_by_type(:task) }
  let(:type_params) { { work_item_type_id: task_type.id } }
  let(:params) do
    {
      title: 'Awesome work item',
      line_number_start: 1,
      line_number_end: 3,
      lock_version: work_item_to_update.lock_version
    }.merge(type_params)
  end

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  shared_examples 'CreateFromTask service with invalid params' do
    it { is_expected.to be_error }

    it 'does not create a work item or links' do
      expect do
        service_result
      end.to not_change(WorkItem, :count).and(
        not_change(WorkItems::ParentLink, :count)
      )
    end
  end

  describe '#execute' do
    subject(:service_result) do
      described_class.new(work_item: work_item_to_update, current_user: current_user, work_item_params: params).execute
    end

    context 'when work item params are valid' do
      it { is_expected.to be_success }

      it 'creates a work item and creates parent link to the original work item' do
        expect do
          service_result
        end.to change(WorkItem, :count).by(1).and(
          change(WorkItems::ParentLink, :count).by(1)
        )

        expect(work_item_to_update.reload.work_item_children).not_to be_empty
      end

      it 'replaces the original issue markdown description with new work item reference' do
        service_result

        created_work_item = WorkItem.last

        expect(list_work_item.description).to eq("- [ ] #{created_work_item.to_reference}+")
      end

      it_behaves_like 'title with extra spaces'

      context 'when passing the work item type as an object' do
        let(:type_params) { { work_item_type: task_type } }

        it 'creates a work item and creates parent link to the original work item' do
          expect do
            service_result
          end.to change(WorkItem, :count).by(1).and(
            change(WorkItems::ParentLink, :count).by(1)
          )
        end
      end

      context 'when passing the work item type as an object and also by id' do
        let(:type_params) do
          { work_item_type: WorkItems::Type.default_by_type(:issue), work_item_type_id: task_type.id }
        end

        it 'takes ID value over the work item type object' do
          expect do
            service_result
          end.to change(WorkItem, :count).by(1).and(
            change(WorkItems::ParentLink, :count).by(1)
          )
          created_work_item = WorkItem.last
          expect(created_work_item.work_item_type).to eq(task_type)
        end
      end
    end

    context 'when last operation fails' do
      before do
        params.merge!(line_number_start: 0)
      end

      it 'rollbacks all operations' do
        expect do
          service_result
        end.to not_change(WorkItem, :count).and(
          not_change(WorkItems::ParentLink, :count)
        )
      end

      it { is_expected.to be_error }

      it 'returns an error message' do
        expect(service_result.errors).to contain_exactly('line_number_start must be greater than 0')
      end
    end

    context 'when work item params are invalid' do
      let(:params) { { title: '' } }

      it_behaves_like 'CreateFromTask service with invalid params'

      it 'returns work item errors' do
        expect(service_result.errors).to contain_exactly("Title can't be blank")
      end
    end
  end
end
