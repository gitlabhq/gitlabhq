# frozen_string_literal: true

RSpec.shared_examples 'allows protected branch crud' do
  it { is_expected.to be_allowed(:read_protected_branch) }
  it { is_expected.to be_allowed(:create_protected_branch) }
  it { is_expected.to be_allowed(:update_protected_branch) }
  it { is_expected.to be_allowed(:destroy_protected_branch) }
end

RSpec.shared_examples 'disallows protected branch crud' do
  it { is_expected.not_to be_allowed(:read_protected_branch) }
  it { is_expected.not_to be_allowed(:create_protected_branch) }
  it { is_expected.not_to be_allowed(:update_protected_branch) }
  it { is_expected.not_to be_allowed(:destroy_protected_branch) }
end

RSpec.shared_examples 'disallows protected branch changes' do
  it { is_expected.to be_allowed(:read_protected_branch) }
  it { is_expected.not_to be_allowed(:create_protected_branch) }
  it { is_expected.not_to be_allowed(:update_protected_branch) }
  it { is_expected.not_to be_allowed(:destroy_protected_branch) }
end
