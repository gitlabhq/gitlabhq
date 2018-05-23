require 'spec_helper'

describe TermAgreement do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:term) }
    it { is_expected.to validate_presence_of(:user) }
  end
end
