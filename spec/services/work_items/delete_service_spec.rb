# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DeleteService, feature_category: :team_planning do
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be_with_reload(:author) { create(:user, guest_of: group) }
  let_it_be_with_reload(:guest) { create(:user, guest_of: group) }
  let_it_be_with_reload(:planner) { create(:user, planner_of: group) }
  let_it_be_with_reload(:owner) { create(:user, owner_of: group) }
  let_it_be_with_reload(:incident) { create(:work_item, :incident, project: project, author: author) }
  let_it_be_with_refind(:work_item) { create(:work_item, project: project, author: author) }
  let(:user) { nil }

  let(:service) { described_class.new(container: project, current_user: user) }

  before_all do
    # note necessary to test note removal as part of work item deletion
    create(:note, project: project, noteable: work_item)
  end

  describe '#execute' do
    subject(:result) { service.execute(work_item) }

    shared_examples 'deletes work item' do
      it { is_expected.to be_success }

      it 'publish WorkItems::WorkItemDeletedEvent' do
        expect { service.execute(work_item) }
          .to publish_event(::WorkItems::WorkItemDeletedEvent).with({
            id: work_item.id,
            namespace_id: work_item.namespace_id,
            previous_work_item_parent_id: work_item.work_item_parent&.id
          }.tap(&:compact_blank!))
      end
    end

    shared_examples 'fails to delete work item' do
      it { is_expected.to be_error }

      it 'returns error messages' do
        expect(result.errors).to contain_exactly('User not authorized to delete work item')
      end

      it 'does not publish WorkItems::WorkItemDeletedEvent' do
        expect { service.execute(work_item) }
          .not_to publish_event(::WorkItems::WorkItemDeletedEvent)
      end
    end

    context 'when user is guest' do
      let(:user) { guest }

      it_behaves_like 'fails to delete work item'

      context 'with incident type' do
        let(:work_item) { incident }

        it_behaves_like 'fails to delete work item'
      end
    end

    context 'when user is author' do
      let(:user) { author }

      it_behaves_like 'deletes work item'

      context 'with incident type' do
        let(:work_item) { incident }

        it_behaves_like 'fails to delete work item'
      end
    end

    context 'when user is planner' do
      let(:user) { planner }

      it_behaves_like 'deletes work item'

      context 'with incident type' do
        let(:work_item) { incident }

        it_behaves_like 'fails to delete work item'
      end
    end

    context 'when user is owner' do
      let(:user) { owner }

      it_behaves_like 'deletes work item'

      context 'with incident type' do
        let(:work_item) { incident }

        it_behaves_like 'deletes work item'
      end
    end

    context 'when work item has assignees' do
      # `freeze: false` is required in this spec: one or more `let_it_be` subjects
      # cannot be frozen by default (deep_freeze traversal failure, a non-AR
      # subject, or an in-memory mutation that survives reload/refind). Do not
      # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
      # (see gitlab-org/gitlab#602925).
      let_it_be_with_reload(:assignee) { create(:user, guest_of: group) }
      let_it_be(:work_item_with_assignee, freeze: false) do
        create(:work_item, project: project, author: owner, assignees: [assignee])
      end

      let(:user) { owner }

      it 'invalidates the issues count cache for each assignee' do
        expect(assignee).to receive(:invalidate_cache_counts).once

        service.execute(work_item_with_assignee)
      end
    end

    # currently we don't expect destroy to fail. Mocking here for coverage and keeping
    # the service's return type consistent
    context 'when there are errors preventing to delete the work item' do
      let(:user) { owner }

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
end
