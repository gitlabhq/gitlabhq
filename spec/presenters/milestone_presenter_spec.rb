# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MilestonePresenter do
  let(:user) { build_stubbed(:user) }
  let(:group) { build_stubbed(:group) }
  let(:milestone) { build_stubbed(:milestone, group: group) }
  let(:presenter) { described_class.new(milestone, current_user: user) }

  describe '#milestone_path' do
    it 'returns correct path' do
      expect(presenter.milestone_path).to eq("/groups/#{group.full_path}/-/milestones/#{milestone.iid}")
    end
  end
end
