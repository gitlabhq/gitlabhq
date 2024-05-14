# frozen_string_literal: true

RSpec.shared_context 'with an approval rule and approver' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:approver) { create(:user) }

  let!(:protected_environment) do
    create(
      :protected_environment,
      project: project,
      name: environment.name
    )
  end

  let!(:approval_rule) do
    create(
      :protected_environment_approval_rule,
      protected_environment: protected_environment,
      user: approver,
      required_approvals: 1
    )
  end
end

RSpec.shared_context 'with a non approver' do
  let_it_be(:non_approver) { create(:user) }
end
