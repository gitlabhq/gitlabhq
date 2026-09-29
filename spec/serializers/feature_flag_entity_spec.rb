# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagEntity do
  let(:feature_flag) { build_stubbed(:operations_feature_flag, project: project, iid: 1) }
  let(:project) { create(:project, developers: user) }
  let(:request) { double('request', current_user: user) }
  let(:user) { create(:user) }
  let(:entity) { described_class.new(feature_flag, request: request) }

  subject { entity.as_json }

  it 'has feature flag attributes' do
    expect(subject).to include(:id, :active, :created_at, :updated_at,
      :description, :name, :edit_path, :destroy_path)
  end
end
