# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PerformanceBar do
  it { expect(described_class.l1_cache_backend).to eq(Gitlab::ProcessMemoryCache.cache_backend) }
  it { expect(described_class.l2_cache_backend).to eq(Rails.cache) }

  describe '.allowed_for_user?' do
    let(:user) { create(:user) }

    before do
      stub_application_setting(performance_bar_allowed_group_id: -1)
    end

    it 'returns false when given user is nil' do
      expect(described_class.allowed_for_user?(nil)).to be_falsy
    end

    it 'returns true when given user is an admin' do
      user = build_stubbed(:user, :admin)

      expect(described_class.allowed_for_user?(user)).to be_truthy
    end

    it 'returns false when allowed_group_id is nil' do
      expect(described_class).to receive(:allowed_group_id).and_return(nil)

      expect(described_class.allowed_for_user?(user)).to be_falsy
    end

    context 'when allowed group ID does not exist' do
      it 'returns false' do
        expect(described_class.allowed_for_user?(user)).to be_falsy
      end
    end

    context 'when allowed group exists' do
      let!(:my_group) { create(:group, path: 'my-group') }

      before do
        stub_application_setting(performance_bar_allowed_group_id: my_group.id)
      end

      context 'when user is not a member of the allowed group' do
        it 'returns false' do
          expect(described_class.allowed_for_user?(user)).to be_falsy
        end

        context 'caching of allowed user IDs' do
          subject { described_class.allowed_for_user?(user) }

          before do
            # Warm the caches
            described_class.allowed_for_user?(user)
          end

          it_behaves_like 'allowed user IDs are cached'
        end
      end

      context 'when user is a member of the allowed group' do
        before do
          my_group.add_developer(user)
        end

        it 'returns true' do
          expect(described_class.allowed_for_user?(user)).to be_truthy
        end

        context 'caching of allowed user IDs' do
          subject { described_class.allowed_for_user?(user) }

          before do
            # Warm the caches
            described_class.allowed_for_user?(user)
          end

          it_behaves_like 'allowed user IDs are cached'
        end
      end
    end

    context 'when allowed group is nested' do
      let!(:nested_my_group) { create(:group, parent: create(:group, path: 'my-org'), path: 'my-group') }

      before do
        create(:group, path: 'my-group')
        nested_my_group.add_developer(user)
        stub_application_setting(performance_bar_allowed_group_id: nested_my_group.id)
      end

      it 'returns the nested group' do
        expect(described_class.allowed_for_user?(user)).to be_truthy
      end
    end

    context 'when a nested group has the same path' do
      before do
        create(:group, :nested, path: 'my-group').add_developer(user)
      end

      it 'returns false' do
        expect(described_class.allowed_for_user?(user)).to be_falsy
      end
    end
  end
end
