# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::SubscriptionPortal do
  using RSpec::Parameterized::TableSyntax
  include SubscriptionPortalHelper

  let(:env_value) { nil }

  before do
    stub_env('CUSTOMER_PORTAL_URL', env_value)
  end

  describe 'class methods' do
    describe '.registration_validation_form_id' do
      subject { described_class.registration_validation_form_id }

      it { is_expected.to eq('cc_registration_validation') }
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
