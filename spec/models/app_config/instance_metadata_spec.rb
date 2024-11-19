# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/models/app_config/instance_metadata'
require_relative '../../../app/models/app_config/kas_metadata'

RSpec.describe AppConfig::InstanceMetadata, feature_category: :api do
  it 'has the correct properties' do
    expect(described_class.new).to have_attributes(
      version: Gitlab::VERSION,
      revision: Gitlab.revision,
      kas: kind_of(AppConfig::KasMetadata),
      enterprise: Gitlab.ee?
    )
  end
end
