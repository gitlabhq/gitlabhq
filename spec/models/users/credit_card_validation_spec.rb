# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CreditCardValidation do
  it { is_expected.to belong_to(:user) }
end
