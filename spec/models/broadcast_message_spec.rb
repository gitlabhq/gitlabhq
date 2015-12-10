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

describe BroadcastMessage, models: true do
  subject { create(:broadcast_message) }

  it { is_expected.to be_valid }

  describe 'validations' do
    let(:triplet) { '#000' }
    let(:hex)     { '#AABBCC' }

    it { is_expected.to allow_value(nil).for(:color) }
    it { is_expected.to allow_value(triplet).for(:color) }
    it { is_expected.to allow_value(hex).for(:color) }
    it { is_expected.not_to allow_value('000').for(:color) }

    it { is_expected.to allow_value(nil).for(:font) }
    it { is_expected.to allow_value(triplet).for(:font) }
    it { is_expected.to allow_value(hex).for(:font) }
    it { is_expected.not_to allow_value('000').for(:font) }
  end

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
