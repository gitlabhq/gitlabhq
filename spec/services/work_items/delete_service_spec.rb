# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DeleteService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:owner) { create(:user, owner_of: group) }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project, author: guest) }

  let(:user) { guest }

  let(:service) { described_class.new(container: project, current_user: user) }

  before_all do
    # note necessary to test note removal as part of work item deletion
    create(:note, project: project, noteable: work_item)
  end

  describe '#execute' do
    subject(:result) { service.execute(work_item) }

    context 'when user can delete the work item' do
      it { is_expected.to be_success }

      it 'publish WorkItems::WorkItemDeletedEvent' do
        expect { service.execute(work_item) }
          .to publish_event(::WorkItems::WorkItemDeletedEvent)
            .with({
              id: work_item.id,
              namespace_id: work_item.namespace_id,
              work_item_parent_id: work_item.work_item_parent&.id
            }.tap(&:compact_blank!))
      end

      context 'when work item exists at the group level' do
        let_it_be(:work_item) { create(:work_item, :group_level, namespace: group) }

        context 'when the user is owner of the group' do
          let_it_be(:work_item) { create(:work_item, :group_level, namespace: group) }
          let(:user) { owner }

          it { is_expected.to be_success }
        end

        context 'when the user is a guest of the group but author of the work item' do
          let_it_be(:work_item) { create(:work_item, :group_level, namespace: group, author: guest) }

          it { is_expected.to be_success }
        end
      end

      # currently we don't expect destroy to fail. Mocking here for coverage and keeping
      # the service's return type consistent
      context 'when there are errors preventing to delete the work item' do
        before do
          allow(work_item).to receive(:destroy).and_return(false)
          work_item.errors.add(:title)
        end

        it { is_expected.to be_error }

        it 'returns error messages' do
          expect(result.errors).to contain_exactly('Title is invalid')
        end
      end
    end

    context 'when user cannot delete the work item' do
      let(:user) { create(:user) }

      it { is_expected.to be_error }

      it 'returns error messages' do
        expect(result.errors).to contain_exactly('User not authorized to delete work item')
      end

      it 'does not publish WorkItems::WorkItemDeletedEvent' do
        expect { service.execute(work_item) }
          .not_to publish_event(::WorkItems::WorkItemDeletedEvent)
      end
    end
  end
end
