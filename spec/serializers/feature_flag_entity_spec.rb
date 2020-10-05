# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagEntity do
  let(:feature_flag) { create(:operations_feature_flag, project: project) }
  let(:project) { create(:project) }
  let(:request) { double('request', current_user: user) }
  let(:user) { create(:user) }
  let(:entity) { described_class.new(feature_flag, request: request) }

  before do
    project.add_developer(user)
  end

  subject { entity.as_json }

  it 'has feature flag attributes' do
    expect(subject).to include(:id, :active, :created_at, :updated_at,
      :description, :name, :edit_path, :destroy_path)
  end
end
