# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::AllowedTargetFilterService do
  include DesignManagementTestHelpers

  let_it_be(:authorized_group) { create(:group, :private) }
  let_it_be(:authorized_project) { create(:project, group: authorized_group) }
  let_it_be(:unauthorized_group) { create(:group, :private) }
  let_it_be(:unauthorized_project) { create(:project, group: unauthorized_group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:authorized_issue) { create(:issue, project: authorized_project) }
  let_it_be(:authorized_issue_todo) { create(:todo, project: authorized_project, target: authorized_issue, user: user) }
  let_it_be(:unauthorized_issue) { create(:issue, project: unauthorized_project) }
  let_it_be(:unauthorized_issue_todo) { create(:todo, project: unauthorized_project, target: unauthorized_issue, user: user) }
  let_it_be(:authorized_design) { create(:design, issue: authorized_issue) }
  let_it_be(:authorized_design_todo) { create(:todo, project: authorized_project, target: authorized_design, user: user) }
  let_it_be(:unauthorized_design) { create(:design, issue: unauthorized_issue) }
  let_it_be(:unauthorized_design_todo) { create(:todo, project: unauthorized_project, target: unauthorized_design, user: user) }

  # Cannot use let_it_be with MRs
  let(:authorized_mr) { create(:merge_request, source_project: authorized_project) }
  let(:authorized_mr_todo) { create(:todo, project: authorized_project, user: user, target: authorized_mr) }
  let(:unauthorized_mr) { create(:merge_request, source_project: unauthorized_project) }
  let(:unauthorized_mr_todo) { create(:todo, project: unauthorized_project, user: user, target: unauthorized_mr) }

  before_all do
    authorized_group.add_developer(user)
  end

  describe '#execute' do
    subject(:execute_service) { described_class.new(all_todos, user).execute }

    let!(:all_todos) { authorized_todos + unauthorized_todos }

    let(:authorized_todos) do
      [
        authorized_mr_todo,
        authorized_issue_todo,
        authorized_design_todo
      ]
    end

    let(:unauthorized_todos) do
      [
        unauthorized_mr_todo,
        unauthorized_issue_todo,
        unauthorized_design_todo
      ]
    end

    before do
      enable_design_management
    end

    it { is_expected.to match_array(authorized_todos) }
  end
end
