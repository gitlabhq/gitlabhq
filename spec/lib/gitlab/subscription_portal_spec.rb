# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::SubscriptionPortal do
  using RSpec::Parameterized::TableSyntax
  include SubscriptionPortalHelper

  let(:env_value) { nil }

  before do
    stub_env('CUSTOMER_PORTAL_URL', env_value)
  end

  describe '.default_subscriptions_url' do
    where(:test, :development, :result) do
      false | false | prod_customers_url
      false | true | staging_customers_url
      true | false | staging_customers_url
    end

    before do
      allow(Rails).to receive_message_chain(:env, :test?).and_return(test)
      allow(Rails).to receive_message_chain(:env, :development?).and_return(development)
    end

    with_them do
      subject { described_class.default_subscriptions_url }

      it { is_expected.to eq(result) }
    end
  end

  describe '.subscriptions_url' do
    subject { described_class.subscriptions_url }

    context 'when CUSTOMER_PORTAL_URL ENV is unset' do
      it { is_expected.to eq(staging_customers_url) }
    end

    context 'when CUSTOMER_PORTAL_URL ENV is set' do
      let(:env_value) { 'https://customers.example.com' }

      it { is_expected.to eq(env_value) }
    end
  end

  describe '.subscriptions_comparison_url' do
    subject { described_class.subscriptions_comparison_url }

    link_match = %r{\Ahttps://about\.gitlab\.((cn/pricing/saas)|(com/pricing/gitlab-com))/feature-comparison\z}

    it { is_expected.to match(link_match) }
  end

  describe 'class methods' do
    where(:method_name, :result) do
      :default_subscriptions_url | staging_customers_url
      :payment_form_url | "#{staging_customers_url}/payment_forms/cc_validation"
      :payment_validation_form_id | 'payment_method_validation'
      :registration_validation_form_url | "#{staging_customers_url}/payment_forms/cc_registration_validation"
      :registration_validation_form_id | 'cc_registration_validation'
      :subscriptions_graphql_url | "#{staging_customers_url}/graphql"
      :subscriptions_more_minutes_url | "#{staging_customers_url}/buy_pipeline_minutes"
      :subscriptions_more_storage_url | "#{staging_customers_url}/buy_storage"
      :subscriptions_manage_url | "#{staging_customers_url}/subscriptions"
      :subscriptions_legacy_sign_in_url | "#{staging_customers_url}/customers/sign_in?legacy=true"
      :subscriptions_instance_review_url | "#{staging_customers_url}/instance_review"
      :subscriptions_gitlab_plans_url | "#{staging_customers_url}/gitlab_plans"
      :edit_account_url | "#{staging_customers_url}/customers/edit"
    end

    with_them do
      subject { described_class.send(method_name) }

      it { is_expected.to eq(result) }
    end
  end

  describe '.add_extra_seats_url' do
    subject { described_class.add_extra_seats_url(group_id) }

    let(:group_id) { 153 }

    it do
      url = "#{staging_customers_url}/gitlab/namespaces/#{group_id}/extra_seats"
      is_expected.to eq(url)
    end
  end

  describe '.upgrade_subscription_url' do
    subject { described_class.upgrade_subscription_url(group_id, plan_id) }

    let(:group_id) { 153 }
    let(:plan_id) { 5 }

    it do
      url = "#{staging_customers_url}/gitlab/namespaces/#{group_id}/upgrade/#{plan_id}"
      is_expected.to eq(url)
    end
  end

  describe '.renew_subscription_url' do
    subject { described_class.renew_subscription_url(group_id) }

    let(:group_id) { 153 }

    it do
      url = "#{staging_customers_url}/gitlab/namespaces/#{group_id}/renew"
      is_expected.to eq(url)
    end
  end

  describe 'constants' do
    where(:constant_name, :result) do
      'REGISTRATION_VALIDATION_FORM_ID' | 'cc_registration_validation'
    end

    with_them do
      subject { "#{described_class}::#{constant_name}".constantize }

      it { is_expected.to eq(result) }
    end
  end
end
