# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DisallowTwoFactorForGroupWorker do
  let_it_be(:group) { create(:group, require_two_factor_authentication: true) }
  let_it_be(:user) { create(:user, require_two_factor_authentication_from_group: true) }

  it "updates group" do
    described_class.new.perform(group.id)

    expect(group.reload.require_two_factor_authentication).to eq(false)
  end

  it "updates group members" do
    group.add_user(user, GroupMember::DEVELOPER)

    described_class.new.perform(group.id)

    expect(user.reload.require_two_factor_authentication_from_group).to eq(false)
  end
end
