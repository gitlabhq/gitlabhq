# frozen_string_literal: true

RSpec.shared_examples 'allows branch rule crud' do
  it { expect_allowed(:read_branch_rule) }
  it { expect_allowed(:create_branch_rule) }
  it { expect_allowed(:update_branch_rule) }
  it { expect_allowed(:delete_branch_rule) }
end

RSpec.shared_examples 'disallows branch rule crud' do
  it { expect_disallowed(:read_branch_rule) }
  it { expect_disallowed(:create_branch_rule) }
  it { expect_disallowed(:update_branch_rule) }
  it { expect_disallowed(:delete_branch_rule) }
end

RSpec.shared_examples 'disallows branch rule changes' do
  it { expect_allowed(:read_branch_rule) }
  it { expect_disallowed(:create_branch_rule) }
  it { expect_disallowed(:update_branch_rule) }
  it { expect_disallowed(:delete_branch_rule) }
end
