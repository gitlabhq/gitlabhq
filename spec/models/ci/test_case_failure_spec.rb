# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TestCaseFailure do
  describe 'relationships' do
    it { is_expected.to belong_to(:build) }
    it { is_expected.to belong_to(:test_case) }
  end

  describe 'validations' do
    subject { build(:ci_test_case_failure) }

    it { is_expected.to validate_presence_of(:test_case) }
    it { is_expected.to validate_presence_of(:build) }
    it { is_expected.to validate_presence_of(:failed_at) }
  end
end
