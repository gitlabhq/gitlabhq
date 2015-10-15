# == Schema Information
#
# Table name: broadcast_messages
#
#  id         :integer          not null, primary key
#  message    :text             not null
#  starts_at  :datetime
#  ends_at    :datetime
#  alert_type :integer
#  created_at :datetime
#  updated_at :datetime
#  color      :string(255)
#  font       :string(255)
#

require 'spec_helper'

describe BroadcastMessage do
  subject { create(:broadcast_message) }

  it { is_expected.to be_valid }

  describe :current do
    it "should return last message if time match" do
      broadcast_message = create(:broadcast_message, starts_at: Time.now.yesterday, ends_at: Time.now.tomorrow)
      expect(BroadcastMessage.current).to eq(broadcast_message)
    end

    it "should return nil if time not come" do
      create(:broadcast_message, starts_at: Time.now.tomorrow, ends_at: Time.now + 2.days)
      expect(BroadcastMessage.current).to be_nil
    end

    it "should return nil if time has passed" do
      create(:broadcast_message, starts_at: Time.now - 2.days, ends_at: Time.now.yesterday)
      expect(BroadcastMessage.current).to be_nil
    end
  end
end
