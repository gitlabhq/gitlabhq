# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DisallowTwoFactorForGroupWorker, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group, require_two_factor_authentication: true) }
  let_it_be(:user) { create(:user, require_two_factor_authentication_from_group: true) }

  it "updates group" do
    described_class.new.perform(group.id)

    expect(group.reload.require_two_factor_authentication).to eq(false)
  end

  it "updates group members", :sidekiq_inline do
    group.add_member(user, GroupMember::DEVELOPER)

    described_class.new.perform(group.id)

    expect(user.reload.require_two_factor_authentication_from_group).to eq(false)
  end
end
