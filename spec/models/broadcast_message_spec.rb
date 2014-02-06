# == Schema Information
#
# Table name: broadcast_messages
#
#  id         :integer          not null, primary key
#  message    :text             default(""), not null
#  starts_at  :datetime
#  ends_at    :datetime
#  alert_type :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color      :string(255)
#  font       :string(255)
#

require 'spec_helper'

describe BroadcastMessage do
  subject { create(:broadcast_message) }

  it { should be_valid }

  describe :current do
    it "should return last message if time match" do
      broadcast_message = create(:broadcast_message, starts_at: Time.now.yesterday, ends_at: Time.now.tomorrow)
      BroadcastMessage.current.should == broadcast_message
    end

    it "should return nil if time not come" do
      broadcast_message = create(:broadcast_message, starts_at: Time.now.tomorrow, ends_at: Time.now + 2.days)
      BroadcastMessage.current.should be_nil
    end

    it "should return nil if time has passed" do
      broadcast_message = create(:broadcast_message, starts_at: Time.now - 2.days, ends_at: Time.now.yesterday)
      BroadcastMessage.current.should be_nil
    end
  end
end
