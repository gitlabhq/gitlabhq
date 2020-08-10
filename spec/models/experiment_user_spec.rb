# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExperimentUser do
  describe 'Associations' do
    it { is_expected.to belong_to(:experiment) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:group_type) }
  end
end
