# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceLabelEventPolicy, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:private_project) { create(:project, :private) }

  describe '#read_resource_label_event' do
    context 'with non-member user' do
      it 'does not allow to read event' do
        event = build_event(project)

        expect(permissions(user, event)).to be_disallowed(:read_resource_label_event)
      end
    end

    context 'with member user' do
      before do
        project.add_guest(user)
      end

      it 'allows to read event for accessible label' do
        event = build_event(project)

        expect(permissions(user, event)).to be_allowed(:read_resource_label_event)
      end

      it 'does not allow to read event for not accessible label' do
        event = build_event(private_project)

        expect(permissions(user, event)).to be_disallowed(:read_resource_label_event)
      end
    end
  end

  describe '#read_label' do
    it 'allows to read deleted label' do
      event = build(:resource_label_event, issue: issue, label: nil)

      expect(permissions(user, event)).to be_allowed(:read_label)
    end

    it 'allows to read accessible label' do
      project.add_guest(user)
      event = build_event(project)

      expect(permissions(user, event)).to be_allowed(:read_label)
    end

    it 'does not allow to read not accessible label' do
      event = build_event(private_project)

      expect(permissions(user, event)).to be_disallowed(:read_label)
    end
  end

  def build_event(label_project)
    label = create(:label, project: label_project)

    build(:resource_label_event, issue: issue, label: label)
  end

  def permissions(user, issue)
    described_class.new(user, issue)
  end
end
