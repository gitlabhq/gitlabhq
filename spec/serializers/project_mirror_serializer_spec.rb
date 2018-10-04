require 'spec_helper'

describe ProjectMirrorSerializer do
  it 'represents ProjectMirror entities' do
    expect(described_class.entity_class).to eq(ProjectMirrorEntity)
  end
end
