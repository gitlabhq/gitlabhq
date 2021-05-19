# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::SubscriptionPortal, skip: Gitlab.jh? do
  using RSpec::Parameterized::TableSyntax

  where(:method_name, :test, :development, :result) do
    :default_subscriptions_url | false | false  | 'https://customers.gitlab.com'
    :default_subscriptions_url | false | true   | 'https://customers.stg.gitlab.com'
    :default_subscriptions_url | true  | false  | 'https://customers.stg.gitlab.com'
    :payment_form_url          | false | false  | 'https://customers.gitlab.com/payment_forms/cc_validation'
    :payment_form_url          | false | true   | 'https://customers.stg.gitlab.com/payment_forms/cc_validation'
    :payment_form_url          | true  | false  | 'https://customers.stg.gitlab.com/payment_forms/cc_validation'
  end

  with_them do
    subject { described_class.method(method_name).call }

    before do
      allow(Rails).to receive_message_chain(:env, :test?).and_return(test)
      allow(Rails).to receive_message_chain(:env, :development?).and_return(development)
    end

    it { is_expected.to eq(result) }
  end
end
