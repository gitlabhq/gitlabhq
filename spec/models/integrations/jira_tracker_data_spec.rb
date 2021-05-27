# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::JiraTrackerData do
  describe 'associations' do
    it { is_expected.to belong_to(:integration) }
  end

  describe 'deployment_type' do
    it { is_expected.to define_enum_for(:deployment_type).with_values([:unknown, :server, :cloud]).with_prefix(:deployment) }
  end

  describe 'encrypted attributes' do
    subject { described_class.encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:api_url, :password, :url, :username) }
  end
end
