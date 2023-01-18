# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMirrorEntity, feature_category: :source_code_management do
  let(:project) { build(:project, :repository, :remote_mirror) }
  let(:entity) { described_class.new(project) }

  subject { entity.as_json }

  it 'exposes project-specific elements' do
    is_expected.to include(:id, :remote_mirrors_attributes)
  end
end
