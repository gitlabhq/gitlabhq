# frozen_string_literal: true

RSpec.shared_context 'four designs in three versions' do
  include DesignManagementTestHelpers

  let_it_be(:issue, freeze: false) { create(:issue) }
  let_it_be(:project, freeze: false) { issue.project }
  let_it_be(:authorized_user, freeze: false) { create(:user) }

  let_it_be(:design_a, freeze: false) { create(:design, issue: issue) }
  let_it_be(:design_b, freeze: false) { create(:design, issue: issue) }
  let_it_be(:design_c, freeze: false) { create(:design, issue: issue) }
  let_it_be(:design_d, freeze: false) { create(:design, issue: issue) }

  let_it_be(:first_version, freeze: false) do
    create(
      :design_version,
      issue: issue,
      created_designs: [design_a],
      modified_designs: [],
      deleted_designs: []
    )
  end

  let_it_be(:second_version, freeze: false) do
    create(
      :design_version,
      issue: issue,
      created_designs: [design_b, design_c, design_d],
      modified_designs: [design_a],
      deleted_designs: []
    )
  end

  let_it_be(:third_version, freeze: false) do
    create(
      :design_version,
      issue: issue,
      created_designs: [],
      modified_designs: [design_a],
      deleted_designs: [design_d]
    )
  end

  before do
    enable_design_management
    project.add_developer(authorized_user)
  end
end
