# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Expirable do
  let_it_be(:no_expire) { create(:project_member) }
  let_it_be(:expire_later) { create(:project_member, expires_at: 8.days.from_now) }
  let_it_be(:expired) { create(:project_member, expires_at: 1.day.from_now) }

  before do
    travel_to(3.days.from_now)
  end

  describe '.expired' do
    it { expect(ProjectMember.expired).to contain_exactly(expired) }

    it 'scopes the query when multiple models are expirable' do
      expired_access_token = create(:personal_access_token, :expired, user: no_expire.user)

      ::Gitlab::Database.allow_cross_joins_across_databases(url:
        'https://gitlab.com/gitlab-org/gitlab/-/issues/422405') do
        expect(PersonalAccessToken.expired.joins(user: :members)).to match_array([expired_access_token])
        expect(PersonalAccessToken.joins(user: :members).merge(ProjectMember.expired)).to eq([])
      end
    end

    it 'works with a timestamp expired_at field', time_travel_to: '2022-03-14T11:30:00Z' do
      expired_deploy_token = create(:deploy_token, expires_at: 5.minutes.ago.iso8601)

      # Here verify that `expires_at` in the SQL uses `Time.current` instead of `Date.current`
      expect(DeployToken.expired).to match_array([expired_deploy_token])
    end
  end

  describe '.not_expired' do
    it { expect(ProjectMember.not_expired).to include(no_expire, expire_later) }
    it { expect(ProjectMember.not_expired).not_to include(expired) }
  end

  describe '#expired?' do
    it { expect(no_expire.expired?).to eq(false) }
    it { expect(expire_later.expired?).to eq(false) }
    it { expect(expired.expired?).to eq(true) }
  end

  describe '#expires?' do
    it { expect(no_expire.expires?).to eq(false) }
    it { expect(expire_later.expires?).to eq(true) }
    it { expect(expired.expires?).to eq(true) }
  end

  describe '#expires_soon?' do
    it { expect(no_expire.expires_soon?).to eq(false) }
    it { expect(expire_later.expires_soon?).to eq(true) }
    it { expect(expired.expires_soon?).to eq(true) }
  end
end
