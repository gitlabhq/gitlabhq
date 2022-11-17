# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Helpers::WeakPasswordErrorEvent do
  let(:user) { build(:user) }

  subject(:helper) { Class.new.include(described_class).new }

  context "when user has a weak password error" do
    before do
      user.password = "password"
      user.valid?
    end

    it "tracks the event" do
      helper.track_weak_password_error(user, 'A', 'B')
      expect_snowplow_event(
        category: 'Gitlab::Tracking::Helpers::WeakPasswordErrorEvent',
        action: 'track_weak_password_error',
        controller: 'A',
        method: 'B'
      )
    end
  end

  context "when user does not have a weak password error" do
    before do
      user.password = "short"
      user.valid?
    end

    it "does not track the event" do
      helper.track_weak_password_error(user, 'A', 'B')
      expect_no_snowplow_event
    end
  end

  context "when user does not have any errors" do
    it "does not track the event" do
      helper.track_weak_password_error(user, 'A', 'B')
      expect_no_snowplow_event
    end
  end
end
