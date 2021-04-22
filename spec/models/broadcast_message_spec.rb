# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BroadcastMessage do
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

    it { is_expected.to allow_value(1).for(:broadcast_type) }
    it { is_expected.not_to allow_value(nil).for(:broadcast_type) }
  end

  shared_examples 'time constrainted' do |broadcast_type|
    it 'returns message if time match' do
      message = create(:broadcast_message, broadcast_type: broadcast_type)

      expect(subject.call).to include(message)
    end

    it 'returns multiple messages if time match' do
      message1 = create(:broadcast_message, broadcast_type: broadcast_type)
      message2 = create(:broadcast_message, broadcast_type: broadcast_type)

      expect(subject.call).to contain_exactly(message1, message2)
    end

    it 'returns empty list if time not come' do
      create(:broadcast_message, :future, broadcast_type: broadcast_type)

      expect(subject.call).to be_empty
    end

    it 'returns empty list if time has passed' do
      create(:broadcast_message, :expired, broadcast_type: broadcast_type)

      expect(subject.call).to be_empty
    end
  end

  shared_examples 'message cache' do |broadcast_type|
    it 'caches the output of the query for two weeks' do
      create(:broadcast_message, broadcast_type: broadcast_type)

      expect(described_class).to receive(:current_and_future_messages).and_call_original.twice

      subject.call

      Timecop.travel(3.weeks) do
        subject.call
      end
    end

    it 'expires the value if a broadcast message has ended', :request_store do
      message = create(:broadcast_message, broadcast_type: broadcast_type, ends_at: Time.current.utc + 1.day)

      expect(subject.call).to match_array([message])
      expect(described_class.cache).to receive(:expire).and_call_original

      Timecop.travel(1.week) do
        2.times { expect(subject.call).to be_empty }
      end
    end

    it 'does not create new records' do
      create(:broadcast_message, broadcast_type: broadcast_type)

      expect { subject.call }.not_to change { described_class.count }
    end

    it 'includes messages that need to be displayed in the future' do
      create(:broadcast_message, broadcast_type: broadcast_type)

      future = create(
        :broadcast_message,
        starts_at: Time.current + 10.minutes,
        ends_at: Time.current + 20.minutes,
        broadcast_type: broadcast_type
      )

      expect(subject.call.length).to eq(1)

      Timecop.travel(future.starts_at) do
        expect(subject.call.length).to eq(2)
      end
    end

    it 'does not clear the cache if only a future message should be displayed' do
      create(:broadcast_message, :future)

      expect(Rails.cache).not_to receive(:delete).with(described_class::CACHE_KEY)
      expect(subject.call.length).to eq(0)
    end
  end

  shared_examples "matches with current path" do |broadcast_type|
    it 'returns message if it matches the target path' do
      message = create(:broadcast_message, target_path: "*/onboarding_completed", broadcast_type: broadcast_type)

      expect(subject.call('/users/onboarding_completed')).to include(message)
    end

    it 'returns message if part of the target path matches' do
      create(:broadcast_message, target_path: "/users/*/issues", broadcast_type: broadcast_type)

      expect(subject.call('/users/name/issues').length).to eq(1)
    end

    it 'returns message if provided a path without a preceding slash' do
      create(:broadcast_message, target_path: "/users/*/issues", broadcast_type: broadcast_type)

      expect(subject.call('users/name/issues').length).to eq(1)
    end

    it 'returns the message for empty target path' do
      create(:broadcast_message, target_path: "", broadcast_type: broadcast_type)

      expect(subject.call('/users/name/issues').length).to eq(1)
    end

    it 'returns the message if target path is nil' do
      create(:broadcast_message, target_path: nil, broadcast_type: broadcast_type)

      expect(subject.call('/users/name/issues').length).to eq(1)
    end

    it 'does not return message if target path does not match' do
      create(:broadcast_message, target_path: "/onboarding_completed", broadcast_type: broadcast_type)

      expect(subject.call('/welcome').length).to eq(0)
    end

    it 'does not return message if target path does not match when using wildcard' do
      create(:broadcast_message, target_path: "/users/*/issues", broadcast_type: broadcast_type)

      expect(subject.call('/group/groupname/issues').length).to eq(0)
    end

    it 'does not return message if target path has no wild card at the end' do
      create(:broadcast_message, target_path: "*/issues", broadcast_type: broadcast_type)

      expect(subject.call('/group/issues/test').length).to eq(0)
    end

    it 'does not return message if target path has wild card at the end' do
      create(:broadcast_message, target_path: "/issues/*", broadcast_type: broadcast_type)

      expect(subject.call('/group/issues/test').length).to eq(0)
    end

    it 'does return message if target path has wild card at the beginning and the end' do
      create(:broadcast_message, target_path: "*/issues/*", broadcast_type: broadcast_type)

      expect(subject.call('/group/issues/test').length).to eq(1)
    end

    it "does not return message if the target path is set but no current path is provided" do
      create(:broadcast_message, target_path: "*/issues/*", broadcast_type: broadcast_type)

      expect(subject.call.length).to eq(0)
    end
  end

  describe '.current', :use_clean_rails_memory_store_caching do
    subject { -> (path = nil) { described_class.current(path) } }

    it_behaves_like 'time constrainted', :banner
    it_behaves_like 'message cache', :banner
    it_behaves_like 'matches with current path', :banner

    it 'returns both types' do
      banner_message = create(:broadcast_message, broadcast_type: :banner)
      notification_message = create(:broadcast_message, broadcast_type: :notification)

      expect(subject.call).to contain_exactly(banner_message, notification_message)
    end
  end

  describe '.current_banner_messages', :use_clean_rails_memory_store_caching do
    subject { -> (path = nil) { described_class.current_banner_messages(path) } }

    it_behaves_like 'time constrainted', :banner
    it_behaves_like 'message cache', :banner
    it_behaves_like 'matches with current path', :banner

    it 'only returns banners' do
      banner_message = create(:broadcast_message, broadcast_type: :banner)
      create(:broadcast_message, broadcast_type: :notification)

      expect(subject.call).to contain_exactly(banner_message)
    end
  end

  describe '.current_notification_messages', :use_clean_rails_memory_store_caching do
    subject { -> (path = nil) { described_class.current_notification_messages(path) } }

    it_behaves_like 'time constrainted', :notification
    it_behaves_like 'message cache', :notification
    it_behaves_like 'matches with current path', :notification

    it 'only returns notifications' do
      notification_message = create(:broadcast_message, broadcast_type: :notification)
      create(:broadcast_message, broadcast_type: :banner)

      expect(subject.call).to contain_exactly(notification_message)
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
      expect(Rails.cache).to receive(:delete).with(described_class::BANNER_CACHE_KEY)
      expect(Rails.cache).to receive(:delete).with(described_class::NOTIFICATION_CACHE_KEY)

      message.flush_redis_cache
    end
  end
end
