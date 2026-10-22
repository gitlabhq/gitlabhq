# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::DeployToken, feature_category: :continuous_delivery do
  describe '#as_json' do
    subject(:json) { described_class.new(deploy_token).as_json }

    context 'when the token is active' do
      let(:deploy_token) { build_stubbed(:deploy_token) }

      it { is_expected.to include(revoked: false, expired: false) }
    end

    context 'when the token has been revoked' do
      let(:deploy_token) { build_stubbed(:deploy_token, :revoked) }

      it { is_expected.to include(revoked: true, expired: false) }
    end

    context 'when the token expired on an earlier day' do
      let(:deploy_token) { build_stubbed(:deploy_token, :expired) }

      it { is_expected.to include(revoked: false, expired: true) }
    end

    context 'when the token expired at the start of the current day' do
      let(:deploy_token) { build_stubbed(:deploy_token, expires_at: Time.current.beginning_of_day) }

      it { is_expected.to include(revoked: false, expired: true) }
    end

    context 'when the token has no expiry' do
      let(:deploy_token) { build_stubbed(:deploy_token, expires_at: nil) }

      it { is_expected.to include(expires_at: nil, expired: false) }
    end
  end
end
