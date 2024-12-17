# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::JiraTrackerData, feature_category: :integrations do
  it_behaves_like Integrations::BaseDataFields

  describe 'deployment_type' do
    specify do
      is_expected.to define_enum_for(:deployment_type).with_values([:unknown, :server, :cloud]).with_prefix(:deployment)
    end
  end

  describe 'encrypted attributes' do
    subject { described_class.attr_encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:api_url, :password, :url, :username) }
  end
end
