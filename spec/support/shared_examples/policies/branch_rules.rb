# frozen_string_literal: true

RSpec.shared_examples 'allows branch rule crud' do
  it { is_expected.to be_allowed(:read_branch_rule) }
  it { is_expected.to be_allowed(:create_branch_rule) }
  it { is_expected.to be_allowed(:update_branch_rule) }
  it { is_expected.to be_allowed(:destroy_branch_rule) }
end

RSpec.shared_examples 'disallows branch rule crud' do
  it { is_expected.not_to be_allowed(:read_branch_rule) }
  it { is_expected.not_to be_allowed(:create_branch_rule) }
  it { is_expected.not_to be_allowed(:update_branch_rule) }
  it { is_expected.not_to be_allowed(:destroy_branch_rule) }
end

RSpec.shared_examples 'disallows branch rule changes' do
  it { is_expected.to be_allowed(:read_branch_rule) }
  it { is_expected.not_to be_allowed(:create_branch_rule) }
  it { is_expected.not_to be_allowed(:update_branch_rule) }
  it { is_expected.not_to be_allowed(:destroy_branch_rule) }
end
