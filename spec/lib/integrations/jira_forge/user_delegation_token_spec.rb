# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::JiraForge::UserDelegationToken, feature_category: :integrations do
  let(:user) { build_stubbed(:user) }
  let(:token) { described_class.build(user: user, account_id: 'acc-1', cloud_id: 'cloud-1') }

  def fit_double(principal: 'acc-1', cloud_id: 'cloud-1')
    instance_double(Atlassian::Forge::InvocationToken, principal: principal, cloud_id: cloud_id)
  end

  it 'round-trips the user id and scope claims' do
    decoded = described_class.decode(token.to_jwt)

    expect(decoded).to have_attributes(user_id: user.id, account_id: 'acc-1', cloud_id: 'cloud-1')
  end

  it 'returns nil for a tampered token' do
    expect(described_class.decode("#{token.to_jwt}tampered")).to be_nil
  end

  it 'returns nil for an expired token' do
    jwt = token.to_jwt

    travel_to((described_class::EXPIRE_TIME + 2.minutes).from_now) do
      expect(described_class.decode(jwt)).to be_nil
    end
  end

  describe '#matches_fit?' do
    it 'is true when the FIT principal and cloud id match the claims' do
      expect(token.matches_fit?(fit_double)).to be(true)
    end

    it 'is false for a different Jira account' do
      expect(token.matches_fit?(fit_double(principal: 'other-account'))).to be(false)
    end

    it 'is false for a different Jira site' do
      expect(token.matches_fit?(fit_double(cloud_id: 'other-cloud'))).to be(false)
    end

    it 'is false when the claims are missing' do
      unscoped = described_class.new(user_id: user.id, account_id: nil, cloud_id: nil)

      expect(unscoped.matches_fit?(fit_double(principal: nil, cloud_id: nil))).to be(false)
    end
  end
end
