# frozen_string_literal: true

require 'spec_helper'

describe BroadcastMessage do
  subject { build(:broadcast_message) }

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

  describe '.current', :use_clean_rails_memory_store_caching do
    it 'returns message if time match' do
      message = create(:broadcast_message)

      expect(described_class.current).to include(message)
    end

    it 'returns multiple messages if time match' do
      message1 = create(:broadcast_message)
      message2 = create(:broadcast_message)

      expect(described_class.current).to contain_exactly(message1, message2)
    end

    it 'returns empty list if time not come' do
      create(:broadcast_message, :future)

      expect(described_class.current).to be_empty
    end

    it 'returns empty list if time has passed' do
      create(:broadcast_message, :expired)

      expect(described_class.current).to be_empty
    end

    it 'caches the output of the query for two weeks' do
      create(:broadcast_message)

      expect(described_class).to receive(:current_and_future_messages).and_call_original.twice

      described_class.current

      Timecop.travel(3.weeks) do
        described_class.current
      end
    end

    it 'does not create new records' do
      create(:broadcast_message)

      expect { described_class.current }.not_to change { described_class.count }
    end

    it 'includes messages that need to be displayed in the future' do
      create(:broadcast_message)

      future = create(
        :broadcast_message,
        starts_at: Time.now + 10.minutes,
        ends_at: Time.now + 20.minutes
      )

      expect(described_class.current.length).to eq(1)

      Timecop.travel(future.starts_at) do
        expect(described_class.current.length).to eq(2)
      end
    end

    it 'does not clear the cache if only a future message should be displayed' do
      create(:broadcast_message, :future)

      expect(Rails.cache).not_to receive(:delete).with(described_class::CACHE_KEY)
      expect(described_class.current.length).to eq(0)
    end

    it 'returns message if it matches the target path' do
      message = create(:broadcast_message, target_path: "*/onboarding_completed")

      expect(described_class.current('/users/onboarding_completed')).to include(message)
    end

    it 'returns message if part of the target path matches' do
      create(:broadcast_message, target_path: "/users/*/issues")

      expect(described_class.current('/users/name/issues').length).to eq(1)
    end

    it 'returns the message for empty target path' do
      create(:broadcast_message, target_path: "")

      expect(described_class.current('/users/name/issues').length).to eq(1)
    end

    it 'returns the message if target path is nil' do
      create(:broadcast_message, target_path: nil)

      expect(described_class.current('/users/name/issues').length).to eq(1)
    end

    it 'does not return message if target path does not match' do
      create(:broadcast_message, target_path: "/onboarding_completed")

      expect(described_class.current('/welcome').length).to eq(0)
    end

    it 'does not return message if target path does not match when using wildcard' do
      create(:broadcast_message, target_path: "/users/*/issues")

      expect(described_class.current('/group/groupname/issues').length).to eq(0)
    end
  end

  describe '#attributes' do
    it 'includes message_html field' do
      expect(subject.attributes.keys).to include("cached_markdown_version", "message_html")
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

  describe '#flush_redis_cache' do
    it 'flushes the Redis cache' do
      message = create(:broadcast_message)

      expect(Rails.cache).to receive(:delete).with(described_class::CACHE_KEY)

      message.flush_redis_cache
    end
  end
end
