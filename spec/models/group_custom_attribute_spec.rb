# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupCustomAttribute do
  describe 'assocations' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    subject { build :group_custom_attribute }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:group_id) }
  end
end
