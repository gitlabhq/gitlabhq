# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Otp::Strategies::Devise do
  let_it_be(:user) { create(:user) }

  let(:otp_code) { 42 }

  subject(:validate) { described_class.new(user).validate(otp_code) }

  it 'calls Devise' do
    expect(user).to receive(:validate_and_consume_otp!).with(otp_code)

    validate
  end
end
