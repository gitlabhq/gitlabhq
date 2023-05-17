# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Custom URLs', 'Subscription Portal', feature_category: :subscription_management do
  using RSpec::Parameterized::TableSyntax
  include SubscriptionPortalHelper

  let(:env_value) { nil }
  let(:staging_env_value) { nil }

  before do
    stub_env('CUSTOMER_PORTAL_URL', env_value)
    stub_env('STAGING_CUSTOMER_PORTAL_URL', staging_env_value)
  end

  describe 'subscription_portal_staging_url' do
    subject { subscription_portal_staging_url }

    context 'when STAGING_CUSTOMER_PORTAL_URL is unset' do
      it { is_expected.to eq(staging_customers_url) }
    end

    context 'when STAGING_CUSTOMER_PORTAL_URL is set' do
      let(:staging_env_value) { 'https://customers.staging.example.com' }

      it { is_expected.to eq(staging_env_value) }
    end
  end

  describe 'subscription_portal_url' do
    subject { subscription_portal_url }

    context 'when CUSTOMER_PORTAL_URL ENV is unset' do
      where(:test, :development, :expected_url) do
        false | false | prod_customers_url
        false | true | subscription_portal_staging_url
        true | false | subscription_portal_staging_url
      end

      before do
        allow(Rails).to receive_message_chain(:env, :test?).and_return(test)
        allow(Rails).to receive_message_chain(:env, :development?).and_return(development)
      end

      with_them do
        it { is_expected.to eq(expected_url) }
      end
    end

    context 'when CUSTOMER_PORTAL_URL ENV is set' do
      let(:env_value) { 'https://customers.example.com' }

      it { is_expected.to eq(env_value) }
    end
  end

  describe 'subscription_portal_instance_review_url' do
    subject { subscription_portal_instance_review_url }

    it { is_expected.to eq("#{staging_customers_url}/instance_review") }
  end
end
