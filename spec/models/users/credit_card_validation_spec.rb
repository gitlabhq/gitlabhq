# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CreditCardValidation do
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_length_of(:holder_name).is_at_most(26) }
  it { is_expected.to validate_numericality_of(:last_digits).is_less_than_or_equal_to(9999) }
end
