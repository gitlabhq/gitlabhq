# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ResourceLinkEvent, type: :model, feature_category: :team_planning do
  it_behaves_like 'a resource event'

  describe 'associations' do
    it { is_expected.to belong_to(:work_item) }
    it { is_expected.to belong_to(:child_work_item) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:child_work_item) }
  end
end
