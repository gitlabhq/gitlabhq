# frozen_string_literal: true

require 'spec_helper'

describe UserHighestRole do
  describe 'associations' do
    it { is_expected.to belong_to(:user).required }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:highest_access_level).in_array([nil, *Gitlab::Access.all_values]) }
  end
end
