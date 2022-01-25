# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::SubscriptionPortal do
  using RSpec::Parameterized::TableSyntax

  let(:env_value) { nil }

  before do
    stub_env('CUSTOMER_PORTAL_URL', env_value)
  end

  describe '.default_subscriptions_url' do
    where(:test, :development, :result) do
      false | false | 'https://customers.gitlab.com'
      false | true  | 'https://customers.staging.gitlab.com'
      true  | false | 'https://customers.staging.gitlab.com'
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
      it { is_expected.to eq('https://customers.staging.gitlab.com') }
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

  context 'url methods' do
    where(:method_name, :result) do
      :default_subscriptions_url         | 'https://customers.staging.gitlab.com'
      :payment_form_url                  | 'https://customers.staging.gitlab.com/payment_forms/cc_validation'
      :registration_validation_form_url  | 'https://customers.staging.gitlab.com/payment_forms/cc_registration_validation'
      :subscriptions_graphql_url         | 'https://customers.staging.gitlab.com/graphql'
      :subscriptions_more_minutes_url    | 'https://customers.staging.gitlab.com/buy_pipeline_minutes'
      :subscriptions_more_storage_url    | 'https://customers.staging.gitlab.com/buy_storage'
      :subscriptions_manage_url          | 'https://customers.staging.gitlab.com/subscriptions'
      :subscriptions_instance_review_url | 'https://customers.staging.gitlab.com/instance_review'
      :subscriptions_gitlab_plans_url    | 'https://customers.staging.gitlab.com/gitlab_plans'
      :edit_account_url                  | 'https://customers.staging.gitlab.com/customers/edit'
    end

    with_them do
      subject { described_class.send(method_name) }

      it { is_expected.to eq(result) }
    end
  end

  describe '.add_extra_seats_url' do
    subject { described_class.add_extra_seats_url(group_id) }

    let(:group_id) { 153 }

    it { is_expected.to eq("https://customers.staging.gitlab.com/gitlab/namespaces/#{group_id}/extra_seats") }
  end

  describe '.upgrade_subscription_url' do
    subject { described_class.upgrade_subscription_url(group_id, plan_id) }

    let(:group_id) { 153 }
    let(:plan_id) { 5 }

    it { is_expected.to eq("https://customers.staging.gitlab.com/gitlab/namespaces/#{group_id}/upgrade/#{plan_id}") }
  end

  describe '.renew_subscription_url' do
    subject { described_class.renew_subscription_url(group_id) }

    let(:group_id) { 153 }

    it { is_expected.to eq("https://customers.staging.gitlab.com/gitlab/namespaces/#{group_id}/renew") }
  end
end
