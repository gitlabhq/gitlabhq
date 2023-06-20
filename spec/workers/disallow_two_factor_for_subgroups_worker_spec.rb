# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DisallowTwoFactorForSubgroupsWorker, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup_with_2fa) { create(:group, parent: group, require_two_factor_authentication: true) }
  let_it_be(:subgroup_without_2fa) { create(:group, parent: group, require_two_factor_authentication: false) }
  let_it_be(:subsubgroup_with_2fa) { create(:group, parent: subgroup_with_2fa, require_two_factor_authentication: true) }

  it "schedules updating subgroups" do
    expect(DisallowTwoFactorForGroupWorker).to receive(:perform_in).with(0, subgroup_with_2fa.id)
    expect(DisallowTwoFactorForGroupWorker).to receive(:perform_in).with(2, subsubgroup_with_2fa.id)

    described_class.new.perform(group.id)
  end
end
