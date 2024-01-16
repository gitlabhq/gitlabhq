# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::Destroy::DestroyedIssuableService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    subject { described_class.new(target.id, target.class.name).execute }

    context 'when target is merge request' do
      let_it_be(:target) { create(:merge_request) }
      let_it_be(:pending_todo) { create(:todo, :pending, project: target.project, target: target, user: user) }
      let_it_be(:done_todo) { create(:todo, :done, project: target.project, target: target, user: user) }

      it 'deletes todos for specified target ID and type' do
        control = ActiveRecord::QueryRecorder.new { subject }

        # Create more todos for the target
        create(:todo, :pending, project: target.project, target: target, user: user)
        create(:todo, :pending, project: target.project, target: target, user: user)
        create(:todo, :done, project: target.project, target: target, user: user)
        create(:todo, :done, project: target.project, target: target, user: user)

        expect { subject }.not_to exceed_query_limit(control)
      end

      it 'invalidates todos cache counts of todo users', :use_clean_rails_redis_caching do
        expect { subject }
          .to change { pending_todo.user.todos_pending_count }.from(1).to(0)
                .and change { done_todo.user.todos_done_count }.from(1).to(0)
      end
    end

    context 'when target is an work item' do
      let_it_be(:target) { create(:work_item) }
      let_it_be(:todo1) { create(:todo, :pending, project: target.project, target: target, user: user) }
      let_it_be(:todo2) { create(:todo, :done, project: target.project, target: target, user: user) }
      # rubocop: disable Cop/AvoidBecomes
      let_it_be(:todo3) { create(:todo, :pending, project: target.project, target: target.becomes(Issue), user: user) }
      let_it_be(:todo4) { create(:todo, :done, project: target.project, target: target.becomes(Issue), user: user) }
      # rubocop: enable Cop/AvoidBecomes

      it 'deletes todos' do
        expect { subject }.to change(Todo, :count).by(-4)
      end
    end
  end
end
