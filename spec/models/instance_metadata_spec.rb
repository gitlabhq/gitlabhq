# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../app/models/instance_metadata'
require_relative '../../app/models/instance_metadata/kas'

RSpec.describe InstanceMetadata do
  it 'has the correct properties' do
    expect(subject).to have_attributes(
      version: Gitlab::VERSION,
      revision: Gitlab.revision,
      kas: kind_of(::InstanceMetadata::Kas),
      enterprise: Gitlab.ee?
    )
  end
end
