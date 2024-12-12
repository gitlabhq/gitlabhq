# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Doorkeeper::AccessGrant, type: :model, feature_category: :system_access do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).class_name('Organizations::Organization').optional(false) }
    it { is_expected.to have_one(:openid_request).class_name('Doorkeeper::OpenidConnect::Request') }
  end
end
