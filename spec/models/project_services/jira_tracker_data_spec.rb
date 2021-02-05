# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraTrackerData do
  describe 'associations' do
    it { is_expected.to belong_to(:service) }
  end

  describe 'deployment_type' do
    it { is_expected.to define_enum_for(:deployment_type).with_values([:unknown, :server, :cloud]).with_prefix(:deployment) }
  end

  describe 'proxy settings' do
    it { is_expected.to validate_length_of(:proxy_address).is_at_most(2048) }
    it { is_expected.to validate_length_of(:proxy_port).is_at_most(5) }
    it { is_expected.to validate_length_of(:proxy_username).is_at_most(255) }
    it { is_expected.to validate_length_of(:proxy_password).is_at_most(255) }
  end

  describe 'encrypted attributes' do
    subject { described_class.encrypted_attributes.keys }

    it {
      is_expected.to contain_exactly(
        :api_url, :password, :proxy_address, :proxy_password, :proxy_port, :proxy_username, :url, :username
      )
    }
  end
end
