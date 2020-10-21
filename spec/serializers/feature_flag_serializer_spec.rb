# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagSerializer do
  let(:serializer) { described_class.new(project: project, current_user: user) }
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:feature_flags) { create_list(:operations_feature_flag, 3) }

  before do
    project.add_developer(user)
  end

  describe '#represent' do
    subject { serializer.represent(feature_flags) }

    it 'includes feature flag attributes' do
      is_expected.to all(include(:id, :active, :created_at, :updated_at,
        :description, :name))
    end
  end
end
