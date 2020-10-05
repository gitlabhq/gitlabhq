# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagSummaryEntity do
  let!(:feature_flag) { create(:operations_feature_flag, project: project) }
  let(:project) { create(:project) }
  let(:request) { double('request', current_user: user) }
  let(:user) { create(:user) }
  let(:entity) { described_class.new(project, request: request) }

  before do
    project.add_developer(user)
  end

  subject { entity.as_json }

  it 'has summary information' do
    expect(subject).to include(:count)
  end
end
