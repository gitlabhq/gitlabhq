# frozen_string_literal: true

require 'spec_helper'

describe MilestoneNote do
  describe '.from_event' do
    let(:author) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:noteable) { create(:issue, author: author, project: project) }
    let(:event) { create(:resource_milestone_event, issue: noteable) }

    subject { described_class.from_event(event, resource: noteable, resource_parent: project) }

    it_behaves_like 'a system note', exclude_project: true do
      let(:action) { 'milestone' }
    end
  end
end
