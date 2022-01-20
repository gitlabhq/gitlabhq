# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Group::CrmSettings do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    subject { build(:crm_settings) }

    it { is_expected.to validate_presence_of(:group) }
  end
end
