# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CreateFromTaskService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:list_work_item, refind: true) { create(:work_item, project: project, description: "- [ ] Item to be converted\n    second line\n    third line") }

  let(:work_item_to_update) { list_work_item }
  let(:spam_params) { double }
  let(:link_params) { {} }
  let(:current_user) { developer }
  let(:params) do
    {
      title: 'Awesome work item',
      work_item_type_id: WorkItems::Type.default_by_type(:task).id,
      line_number_start: 1,
      line_number_end: 3,
      lock_version: work_item_to_update.lock_version
    }
  end

  before_all do
    project.add_developer(developer)
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
    subject(:service_result) { described_class.new(work_item: work_item_to_update, current_user: current_user, work_item_params: params, spam_params: spam_params).execute }

    before do
      stub_spam_services
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
