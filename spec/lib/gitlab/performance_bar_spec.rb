require 'spec_helper'

describe Gitlab::PerformanceBar do
  describe '.enabled?' do
    it 'returns false when given actor is nil' do
      expect(described_class.enabled?(nil)).to be_falsy
    end

    it 'returns false when feature is disabled' do
      actor = double('actor')

      expect(Feature).to receive(:enabled?)
        .with(:gitlab_performance_bar, actor).and_return(false)

      expect(described_class.enabled?(actor)).to be_falsy
    end

    it 'returns true when feature is enabled' do
      actor = double('actor')

      expect(Feature).to receive(:enabled?)
        .with(:gitlab_performance_bar, actor).and_return(true)

      expect(described_class.enabled?(actor)).to be_truthy
    end
  end

  shared_examples 'allowed user IDs are cached in Redis for 10 minutes' do
    before do
      # Warm the Redis cache
      described_class.allowed_user?(user)
    end

    it 'caches the allowed user IDs in Redis', :redis do
      expect do
        expect(described_class.allowed_user?(user)).to be_truthy
      end.not_to exceed_query_limit(0)
    end

    it 'caches the allowed user IDs for 10 minutes', :redis do
      ttl_cached_user_ids = Gitlab::Redis.with do |redis|
        redis.ttl(described_class.cache_key)
      end

      expect(ttl_cached_user_ids).to be <= 10.minutes
    end
  end

  describe '.allowed_user?' do
    let(:user) { create(:user) }

    before do
      stub_performance_bar_setting(allowed_group: 'my-group')
    end

    context 'when allowed group does not exist' do
      it 'returns false' do
        expect(described_class.allowed_user?(user)).to be_falsy
      end
    end

    context 'when allowed group exists' do
      let!(:my_group) { create(:group, path: 'my-group') }

      context 'when user is not a member of the allowed group' do
        it 'returns false' do
          expect(described_class.allowed_user?(user)).to be_falsy
        end

        it_behaves_like 'allowed user IDs are cached in Redis for 10 minutes'
      end

      context 'when user is a member of the allowed group' do
        before do
          my_group.add_developer(user)
        end

        it 'returns true' do
          expect(described_class.allowed_user?(user)).to be_truthy
        end

        it_behaves_like 'allowed user IDs are cached in Redis for 10 minutes'
      end
    end

    context 'when allowed group is nested', :nested_groups do
      let!(:nested_my_group) { create(:group, parent: create(:group, path: 'my-org'), path: 'my-group') }

      before do
        create(:group, path: 'my-group')
        nested_my_group.add_developer(user)
        stub_performance_bar_setting(allowed_group: 'my-org/my-group')
      end

      it 'returns the nested group' do
        expect(described_class.allowed_user?(user)).to be_truthy
      end
    end

    context 'when a nested group has the same path', :nested_groups do
      before do
        create(:group, :nested, path: 'my-group').add_developer(user)
      end

      it 'returns false' do
        expect(described_class.allowed_user?(user)).to be_falsy
      end
    end
  end
end
