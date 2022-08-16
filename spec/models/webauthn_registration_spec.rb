# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebauthnRegistration do
  describe 'relations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:credential_xid) }
    it { is_expected.to validate_presence_of(:public_key) }
    it { is_expected.to validate_presence_of(:counter) }
    it { is_expected.to validate_length_of(:name).is_at_least(0) }
    it { is_expected.not_to allow_value(nil).for(:name) }

    it do
      is_expected.to validate_numericality_of(:counter)
          .only_integer
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(4294967295)
    end
  end
end
