# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceStateEventPolicy, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:issue) { create(:issue, project: project) }

  describe '#read_resource_state_event' do
    context 'with non-member user' do
      it 'does not allow to read event' do
        event = build_event(project)

        expect(permissions(user, event)).to be_disallowed(:read_resource_state_event, :read_note)
      end
    end

    context 'with member user' do
      before do
        project.add_guest(user)
      end

      it 'allows to read event for a state change' do
        event = build_event(project)

        expect(permissions(user, event)).to be_allowed(:read_resource_state_event, :read_note)
      end
    end
  end

  def build_event(label_project)
    build(:resource_state_event, issue: issue, state: 2)
  end

  def permissions(user, issue)
    described_class.new(user, issue)
  end
end
