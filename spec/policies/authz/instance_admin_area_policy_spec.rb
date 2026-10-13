# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::InstanceAdminAreaPolicy, feature_category: :permissions do
  it 'is the registered policy for the :instance_admin_area subject' do
    expect(DeclarativePolicy.class_for(:instance_admin_area)).to eq(described_class)
  end
end
