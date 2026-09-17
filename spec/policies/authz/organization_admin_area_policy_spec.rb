# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::OrganizationAdminAreaPolicy, feature_category: :permissions do
  it 'is the registered policy for the :organization_admin_area subject' do
    expect(DeclarativePolicy.class_for(:organization_admin_area)).to eq(described_class)
  end
end
