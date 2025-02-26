# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UserPreferences::DestroyWorker, type: :worker, feature_category: :team_planning do
  let_it_be(:root_namespace) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:source) { root_namespace }
  let(:source_type) { GroupMember::SOURCE_TYPE }

  let(:event) do
    ::Members::DestroyedEvent.new(
      data: {
        root_namespace_id: root_namespace.id,
        source_id: source.id,
        source_type: source_type,
        user_id: user.id
      }
    )
  end

  subject(:worker) { described_class.new }

  it_behaves_like 'subscribes to event'

  shared_examples 'delete user preferences' do
    context 'when there user has no work item preference' do
      it 'does nothing' do
        expect { consume_event(subscriber: described_class, event: event) }
          .not_to change { WorkItems::UserPreference.count }
      end
    end

    context 'when there user has work item preference' do
      let_it_be(:user_preference) do
        create(:work_item_user_preference, namespace: namespace, user: user)
      end

      it 'destroy the existing user preference' do
        expect { consume_event(subscriber: described_class, event: event) }
          .to change { WorkItems::UserPreference.count }.by(-1)

        expect(WorkItems::UserPreference.exists?(id: user_preference.id)).to be(false)
      end
    end
  end

  context 'when namespace is a group' do
    let_it_be(:namespace) { create(:group, parent: root_namespace) }
    let(:source) { namespace }

    it_behaves_like 'delete user preferences'
  end

  context 'when namespace is a project' do
    let_it_be(:project) { create(:project, group: root_namespace) }
    let_it_be(:namespace) { project.project_namespace }

    let(:source) { project }
    let(:source_type) { ProjectMember::SOURCE_TYPE }

    it_behaves_like 'delete user preferences'
  end
end
