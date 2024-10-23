# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppConfig::InstanceMetadataPolicy, feature_category: :api do
  subject { described_class.new(user, AppConfig::InstanceMetadata.new) }

  context 'for any logged-in user' do
    let(:user) { create(:user) }

    specify { expect_allowed(:read_instance_metadata) }
  end

  context 'for anonymous users' do
    let(:user) { nil }

    specify { expect_disallowed(:read_instance_metadata) }
  end
end
