# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Doorkeeper::AccessToken, type: :model, feature_category: :system_access do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).class_name('Organizations::Organization').optional(false) }
  end
end
