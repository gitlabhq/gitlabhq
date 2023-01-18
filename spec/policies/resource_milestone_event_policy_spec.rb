# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceMilestoneEventPolicy, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:private_project) { create(:project, :private) }

  describe '#read_resource_milestone_event' do
    context 'with non-member user' do
      it 'does not allow to read event' do
        event = build_event(project)

        expect(permissions(user, event)).to be_disallowed(:read_milestone, :read_resource_milestone_event, :read_note)
      end
    end

    context 'with member user' do
      before do
        project.add_guest(user)
      end

      it 'allows to read event for accessible milestone' do
        event = build_event(project)

        expect(permissions(user, event)).to be_allowed(:read_milestone, :read_resource_milestone_event, :read_note)
      end

      it 'does not allow to read event for not accessible milestone' do
        event = build_event(private_project)

        expect(permissions(user, event)).to be_disallowed(:read_milestone, :read_resource_milestone_event, :read_note)
      end
    end
  end

  describe '#read_milestone' do
    before do
      project.add_guest(user)
    end

    it 'allows to read deleted milestone' do
      event = build(:resource_milestone_event, issue: issue, milestone: nil)

      expect(permissions(user, event)).to be_allowed(:read_milestone, :read_resource_milestone_event, :read_note)
    end

    it 'allows to read accessible milestone' do
      event = build_event(project)

      expect(permissions(user, event)).to be_allowed(:read_milestone, :read_resource_milestone_event, :read_note)
    end

    it 'does not allow to read not accessible milestone' do
      event = build_event(private_project)

      expect(permissions(user, event)).to be_disallowed(:read_milestone, :read_resource_milestone_event, :read_note)
    end
  end

  def build_event(project)
    milestone = create(:milestone, project: project)

    build(:resource_milestone_event, issue: issue, milestone: milestone)
  end

  def permissions(user, issue)
    described_class.new(user, issue)
  end
end
