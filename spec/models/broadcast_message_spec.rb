# == Schema Information
#
# Table name: broadcast_messages
#
#  id         :integer          not null, primary key
#  message    :text             not null
#  starts_at  :datetime
#  ends_at    :datetime
#  created_at :datetime
#  updated_at :datetime
#  color      :string(255)
#  font       :string(255)
#

require 'spec_helper'

describe BroadcastMessage, models: true do
  include ActiveSupport::Testing::TimeHelpers

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

  describe '.current' do
    it "should return last message if time match" do
      message = create(:broadcast_message)

      expect(BroadcastMessage.current).to eq message
    end

    it "should return nil if time not come" do
      create(:broadcast_message, :future)

      expect(BroadcastMessage.current).to be_nil
    end

    it "should return nil if time has passed" do
      create(:broadcast_message, :expired)

      expect(BroadcastMessage.current).to be_nil
    end
  end

  describe '#active?' do
    it 'is truthy when started and not ended' do
      message = build(:broadcast_message)

      expect(message).to be_active
    end

    it 'is falsey when ended' do
      message = build(:broadcast_message, :expired)

      expect(message).not_to be_active
    end

    it 'is falsey when not started' do
      message = build(:broadcast_message, :future)

      expect(message).not_to be_active
    end
  end

  describe '#started?' do
    it 'is truthy when starts_at has passed' do
      message = build(:broadcast_message)

      travel_to(3.days.from_now) do
        expect(message).to be_started
      end
    end

    it 'is falsey when starts_at is in the future' do
      message = build(:broadcast_message)

      travel_to(3.days.ago) do
        expect(message).not_to be_started
      end
    end
  end

  describe '#ended?' do
    it 'is truthy when ends_at has passed' do
      message = build(:broadcast_message)

      travel_to(3.days.from_now) do
        expect(message).to be_ended
      end
    end

    it 'is falsey when ends_at is in the future' do
      message = build(:broadcast_message)

      travel_to(3.days.ago) do
        expect(message).not_to be_ended
      end
    end
  end
end
