# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::CreateAndLinkService, feature_category: :portfolio_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:related_work_item, refind: true) { create(:work_item, project: project) }
  let_it_be(:invalid_parent) { create(:work_item, :task, project: project) }

  let(:link_params) { {} }

  let(:params) do
    {
      title: 'Awesome work item',
      description: 'please fix',
      work_item_type_id: WorkItems::Type.default_by_type(:task).id
    }
  end

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  shared_examples 'successful work item and link creator' do
    it 'creates a work item successfully with links' do
      expect do
        service_result
      end.to change(WorkItem, :count).by(1).and(
        change(WorkItems::ParentLink, :count).by(1)
      )
    end

    it 'copies confidential status from the parent' do
      expect do
        service_result
      end.to change(WorkItem, :count).by(1)

      created_task = WorkItem.last

      expect(created_task.confidential).to eq(related_work_item.confidential)
    end
  end

  describe '#execute' do
    subject(:service_result) { described_class.new(project: project, current_user: user, params: params, link_params: link_params).execute }

    context 'when work item params are valid' do
      it { is_expected.to be_success }

      it 'creates a work item successfully with no links' do
        expect do
          service_result
        end.to change(WorkItem, :count).by(1).and(
          not_change(IssueLink, :count)
        )
      end

      it_behaves_like 'title with extra spaces'

      context 'when link params are valid' do
        let(:link_params) { { parent_work_item: related_work_item } }

        context 'when parent is not confidential' do
          it_behaves_like 'successful work item and link creator'
        end

        context 'when parent is confidential' do
          before do
            related_work_item.update!(confidential: true)
          end

          it_behaves_like 'successful work item and link creator'
        end
      end

      context 'when link creation fails' do
        let(:link_params) { { parent_work_item: invalid_parent } }

        it { is_expected.to be_error }

        it 'does not create a link and does not rollback transaction' do
          expect do
            service_result
          end.to not_change(WorkItems::ParentLink, :count).and(
            change(WorkItem, :count).by(1)
          )
        end

        it 'returns a link creation error message' do
          expect(service_result.errors).to contain_exactly(/it's not allowed to add this type of parent item/)
        end
      end
    end

    context 'when work item params are invalid' do
      let(:params) do
        {
          title: '',
          description: 'invalid work item'
        }
      end

      it { is_expected.to be_error }

      it 'does not create a work item or links' do
        expect do
          service_result
        end.to not_change(WorkItem, :count).and(
          not_change(WorkItems::ParentLink, :count)
        )
      end

      it 'returns work item errors' do
        expect(service_result.errors).to contain_exactly("Title can't be blank")
      end
    end
  end
end
