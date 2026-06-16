# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMirrorSerializer, feature_category: :source_code_management do
  it 'represents ProjectMirror entities' do
    expect(described_class.entity_class).to eq(ProjectMirrorEntity)
  end
end
