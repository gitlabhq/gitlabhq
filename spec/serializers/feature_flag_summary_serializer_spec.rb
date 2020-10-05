# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagSummarySerializer do
  let(:serializer) { described_class.new(project: project, current_user: user) }
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:feature_flags) { create(:operations_feature_flag, project: project) }

  before do
    project.add_developer(user)
  end

  describe '#represent' do
    subject { serializer.represent(project) }

    it 'has summary information' do
      expect(subject).to include(:count)
    end
  end
end
