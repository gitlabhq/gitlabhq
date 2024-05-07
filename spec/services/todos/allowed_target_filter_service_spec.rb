# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::AllowedTargetFilterService, feature_category: :team_planning do
  include DesignManagementTestHelpers

  let_it_be(:authorized_group) { create(:group, :private) }
  let_it_be(:authorized_project) { create(:project, group: authorized_group) }
  let_it_be(:unauthorized_group) { create(:group, :private) }
  let_it_be(:unauthorized_project) { create(:project, group: unauthorized_group) }
  let_it_be(:user) { create(:user) }

  let_it_be(:authorized_issue) { create(:issue, project: authorized_project) }
  let_it_be(:authorized_issue_todo) { create(:todo, project: authorized_project, target: authorized_issue, user: user) }
  let_it_be(:authorized_note) { create(:note, noteable: authorized_issue, project: authorized_project) }
  let_it_be(:authorized_note_todo) { create(:todo, project: authorized_project, target: authorized_issue, note: authorized_note, user: user) }
  let_it_be(:confidential_issue) { create(:issue, :confidential, project: authorized_project) }
  let_it_be(:confidential_issue_todo) { create(:todo, project: authorized_project, target: confidential_issue, user: user) }
  let_it_be(:confidential_note) { create(:note, :confidential, noteable: confidential_issue, project: authorized_project) }
  let_it_be(:confidential_note_todo) { create(:todo, project: authorized_project, target: authorized_issue, note: confidential_note, user: user) }
  let_it_be(:unauthorized_issue) { create(:issue, project: unauthorized_project) }
  let_it_be(:unauthorized_issue_todo) { create(:todo, project: unauthorized_project, target: unauthorized_issue, user: user) }
  let_it_be(:authorized_design) { create(:design, issue: authorized_issue) }
  let_it_be(:authorized_design_todo) { create(:todo, project: authorized_project, target: authorized_design, user: user) }
  let_it_be(:unauthorized_design) { create(:design, issue: unauthorized_issue) }
  let_it_be(:unauthorized_design_todo) { create(:todo, project: unauthorized_project, target: unauthorized_design, user: user) }
  let_it_be(:unauthorized_note) { create(:note, noteable: unauthorized_issue, project: unauthorized_project) }
  let_it_be(:unauthorized_note_todo) { create(:todo, project: unauthorized_project, target: unauthorized_issue, note: unauthorized_note, user: user) }

  # Cannot use let_it_be with MRs
  let(:authorized_mr) { create(:merge_request, source_project: authorized_project) }
  let(:authorized_mr_todo) { create(:todo, project: authorized_project, user: user, target: authorized_mr) }
  let(:unauthorized_mr) { create(:merge_request, source_project: unauthorized_project) }
  let(:unauthorized_mr_todo) { create(:todo, project: unauthorized_project, user: user, target: unauthorized_mr) }

  describe '#execute' do
    let(:all_todos) { Todo.where(id: (authorized_todos + unauthorized_todos).map(&:id)) }

    subject(:execute_service) { described_class.new(all_todos, user).execute }

    shared_examples 'allowed Todos filter' do
      before do
        enable_design_management
      end

      it { is_expected.to match_array(authorized_todos) }
    end

    context 'with reporter user' do
      before_all do
        authorized_group.add_reporter(user)
      end

      it_behaves_like 'allowed Todos filter' do
        let(:authorized_todos) do
          [
            authorized_mr_todo,
            authorized_issue_todo,
            confidential_issue_todo,
            confidential_note_todo,
            authorized_design_todo
          ]
        end

        let(:unauthorized_todos) do
          [
            unauthorized_mr_todo,
            unauthorized_issue_todo,
            unauthorized_note_todo,
            unauthorized_design_todo
          ]
        end
      end
    end

    context 'with guest user' do
      before_all do
        authorized_group.add_guest(user)
      end

      it_behaves_like 'allowed Todos filter' do
        let(:authorized_todos) do
          [
            authorized_issue_todo,
            authorized_design_todo
          ]
        end

        let(:unauthorized_todos) do
          [
            authorized_mr_todo,
            confidential_issue_todo,
            confidential_note_todo,
            unauthorized_mr_todo,
            unauthorized_issue_todo,
            unauthorized_note_todo,
            unauthorized_design_todo
          ]
        end
      end
    end

    context 'with a non-member user' do
      it_behaves_like 'allowed Todos filter' do
        let(:authorized_todos) { [] }

        let(:unauthorized_todos) do
          [
            authorized_issue_todo,
            authorized_design_todo,
            authorized_mr_todo,
            confidential_issue_todo,
            confidential_note_todo,
            unauthorized_mr_todo,
            unauthorized_issue_todo,
            unauthorized_note_todo,
            unauthorized_design_todo
          ]
        end
      end
    end
  end
end
