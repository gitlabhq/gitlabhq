# frozen_string_literal: true

require 'spec_helper'

RSpec.describe System::BroadcastMessage, feature_category: :notifications do
  subject { build(:broadcast_message) }

  it { is_expected.to be_valid }

  describe 'associations' do
    it { is_expected.to have_many(:broadcast_message_dismissals) }
  end

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
    it { is_expected.not_to allow_value(nil).for(:target_access_levels) }
    it { is_expected.not_to allow_value(nil).for(:show_in_cli) }

    it do
      is_expected.to validate_inclusion_of(:target_access_levels)
                 .in_array(described_class::ALLOWED_TARGET_ACCESS_LEVELS)
    end

    it do
      is_expected.to validate_inclusion_of(:show_in_cli)
                       .in_array([true, false])
    end
  end

  describe 'default values' do
    subject(:message) { described_class.new }

    it { expect(message.color).to eq('#E75E40') }
    it { expect(message.font).to eq('#FFFFFF') }
  end

  shared_examples 'time constrained' do |broadcast_type|
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

      travel_to(3.weeks.from_now) do
        subject.call
      end
    end

    it 'expires the value if a broadcast message has ended', :request_store do
      message = create(:broadcast_message, broadcast_type: broadcast_type, ends_at: Time.current.utc + 1.day)

      expect(subject.call).to match_array([message])
      expect(described_class.cache).to receive(:expire).and_call_original

      travel_to(1.week.from_now) do
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

      travel_to(future.starts_at + 1.second) do
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

  shared_examples "matches with user access level" do |broadcast_type|
    let_it_be(:target_access_levels) { [Gitlab::Access::GUEST] }

    context 'when target_access_levels is empty' do
      let_it_be(:message) { create(:broadcast_message, target_access_levels: [], broadcast_type: broadcast_type) }

      it 'returns the message if user access level is not nil' do
        expect(subject.call(nil, Gitlab::Access::MINIMAL_ACCESS)).to include(message)
      end

      it 'returns the message if user access level is nil' do
        expect(subject.call).to include(message)
      end
    end

    context 'when target_access_levels is not empty' do
      let_it_be(:message) do
        create(:broadcast_message, target_access_levels: target_access_levels, broadcast_type: broadcast_type)
      end

      it "does not return the message if user access level is nil" do
        expect(subject.call).to be_empty
      end

      it "returns the message if user access level is in target_access_levels" do
        expect(subject.call(nil, Gitlab::Access::GUEST)).to include(message)
      end

      it "does not return the message if user access level is not in target_access_levels" do
        expect(subject.call(nil, Gitlab::Access::MINIMAL_ACCESS)).to be_empty
      end
    end
  end

  shared_examples "handles stale cache data gracefully" do
    # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/353076
    context 'when cache returns stale data (e.g. nil target_access_levels)' do
      let(:message) { build(:broadcast_message, :banner, target_access_levels: nil) }
      let(:cache) { Gitlab::Cache::JsonCaches::JsonKeyed.new }

      before do
        cache.write(described_class::BANNER_CACHE_KEY, [message])
        allow(described_class).to receive(:cache) { cache }
      end

      it 'does not raise error (e.g. NoMethodError from nil.empty?)' do
        expect { subject.call }.not_to raise_error
      end
    end
  end

  describe '.current', :use_clean_rails_memory_store_caching do
    subject do
      ->(path = nil, user_access_level = nil) do
        described_class.current(current_path: path, user_access_level: user_access_level)
      end
    end

    it_behaves_like 'time constrained', :banner
    it_behaves_like 'message cache', :banner
    it_behaves_like 'matches with current path', :banner
    it_behaves_like 'matches with user access level', :banner
    it_behaves_like 'handles stale cache data gracefully'

    context 'when message is from cache' do
      before do
        subject.call
      end

      it_behaves_like 'matches with current path', :banner
      it_behaves_like 'matches with user access level', :banner
      it_behaves_like 'matches with current path', :notification
      it_behaves_like 'matches with user access level', :notification
    end

    it 'returns both types' do
      banner_message = create(:broadcast_message, broadcast_type: :banner)
      notification_message = create(:broadcast_message, broadcast_type: :notification)

      expect(subject.call).to contain_exactly(banner_message, notification_message)
    end
  end

  describe '.current_banner_messages', :use_clean_rails_memory_store_caching do
    subject do
      ->(path = nil, user_access_level = nil) do
        described_class.current_banner_messages(current_path: path, user_access_level: user_access_level)
      end
    end

    it_behaves_like 'time constrained', :banner
    it_behaves_like 'message cache', :banner
    it_behaves_like 'matches with current path', :banner
    it_behaves_like 'matches with user access level', :banner
    it_behaves_like 'handles stale cache data gracefully'

    context 'when message is from cache' do
      before do
        subject.call
      end

      it_behaves_like 'matches with current path', :banner
      it_behaves_like 'matches with user access level', :banner
    end

    it 'only returns banners' do
      banner_message = create(:broadcast_message, broadcast_type: :banner)
      create(:broadcast_message, broadcast_type: :notification)

      expect(subject.call).to contain_exactly(banner_message)
    end
  end

  describe '.current_notification_messages', :use_clean_rails_memory_store_caching do
    subject do
      ->(path = nil, user_access_level = nil) do
        described_class.current_notification_messages(current_path: path, user_access_level: user_access_level)
      end
    end

    it_behaves_like 'time constrained', :notification
    it_behaves_like 'message cache', :notification
    it_behaves_like 'matches with current path', :notification
    it_behaves_like 'matches with user access level', :notification
    it_behaves_like 'handles stale cache data gracefully'

    context 'when message is from cache' do
      before do
        subject.call
      end

      it_behaves_like 'matches with current path', :notification
      it_behaves_like 'matches with user access level', :notification
    end

    it 'only returns notifications' do
      notification_message = create(:broadcast_message, broadcast_type: :notification)
      create(:broadcast_message, broadcast_type: :banner)

      expect(subject.call).to contain_exactly(notification_message)
    end
  end

  describe '.current_show_in_cli_banner_messages', :use_clean_rails_memory_store_caching do
    subject { -> { described_class.current_show_in_cli_banner_messages(user_access_level: 50) } }

    it 'only returns banner messages that has show_in_cli as true' do
      show_in_cli_message = create(:broadcast_message)
      create(:broadcast_message, broadcast_type: :notification)
      create(:broadcast_message, show_in_cli: false)

      expect(subject.call).to contain_exactly(show_in_cli_message)
    end

    it 'filters by user access level' do
      expect(described_class).to receive(:current_banner_messages).with(user_access_level: 50).and_call_original
      subject.call
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

    context 'with GitLab revision changes', :use_clean_rails_redis_caching do
      it 'validates correct cache creating, flushing and cache recreation cycle' do
        message = create(:broadcast_message, broadcast_type: :banner)
        new_strategy_value = { revision: 'abc123', version: '_version_' }

        expect(described_class).to receive(:current_and_future_messages).and_call_original.exactly(4).times

        # 1st non-cache hit
        described_class.current
        # validate seed and cache used
        described_class.current

        # seed the other cache
        original_strategy_value = Gitlab::Cache::JsonCache::STRATEGY_KEY_COMPONENTS
        stub_const('Gitlab::Cache::JsonCaches::JsonKeyed::STRATEGY_KEY_COMPONENTS', new_strategy_value)

        # 2nd non-cache hit
        described_class.current
        # validate seed and cache used
        described_class.current

        # delete on original cache
        stub_const('Gitlab::Cache::JsonCaches::JsonKeyed::STRATEGY_KEY_COMPONENTS', original_strategy_value)
        # validate seed and cache used - this adds another hit and shouldn't will be fixed with append write concept
        described_class.current
        message.destroy!

        # 3rd non-cache hit due to flushing of cache on current Gitlab.revision
        described_class.current
        # validate seed and cache used
        described_class.current

        # other revision of GitLab does gets cache destroyed
        stub_const('Gitlab::Cache::JsonCaches::JsonKeyed::STRATEGY_KEY_COMPONENTS', new_strategy_value)

        # 4th non-cache hit on the simulated other revision
        described_class.current
        # validate seed and cache used
        described_class.current

        # switch back to original and validate cache still exists
        stub_const('Gitlab::Cache::JsonCaches::JsonKeyed::STRATEGY_KEY_COMPONENTS', original_strategy_value)
        # validate seed and cache used
        described_class.current
      end

      it 'handles there being no messages with cache' do
        expect(described_class).to receive(:current_and_future_messages).and_call_original.once

        # 1st non-cache hit
        expect(described_class.current).to eq([])
        # validate seed and cache used
        expect(described_class.current).to eq([])
      end
    end
  end

  describe '#current_and_future_messages' do
    let_it_be(:message_a) { create(:broadcast_message, ends_at: 1.day.ago) }
    let_it_be(:message_b) { create(:broadcast_message, ends_at: Time.current + 2.days) }
    let_it_be(:message_c) { create(:broadcast_message, ends_at: Time.current + 7.days) }

    it 'returns only current and future messages by ascending ends_at' do
      expect(described_class.current_and_future_messages).to eq [message_b, message_c]
    end
  end
end
