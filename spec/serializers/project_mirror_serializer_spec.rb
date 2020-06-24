# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMirrorSerializer do
  it 'represents ProjectMirror entities' do
    expect(described_class.entity_class).to eq(ProjectMirrorEntity)
  end
end
