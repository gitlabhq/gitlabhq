# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventPresenter do
  include Gitlab::Routing.url_helpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:target) { create(:milestone, project: project) }
  let_it_be(:group_event) { create(:event, :created, project: nil, group: group, target: target) }
  let_it_be(:project_event) { create(:event, :created, project: project, target: target) }

  describe '#resource_parent_name' do
    context 'with group event' do
      subject { group_event.present.resource_parent_name }

      it { is_expected.to eq(group.full_name) }
    end

    context 'with project label' do
      subject { project_event.present.resource_parent_name }

      it { is_expected.to eq(project.full_name) }
    end
  end

  describe '#target_link_options' do
    context 'with group event' do
      subject { group_event.present.target_link_options }

      it { is_expected.to eq([group, target]) }
    end

    context 'with project label' do
      subject { project_event.present.target_link_options }

      it { is_expected.to eq([project, target]) }
    end
  end

  describe '#target_type_name' do
    it 'returns design for a design event' do
      expect(build(:design_event).present).to have_attributes(target_type_name: 'design')
    end

    it 'returns project for a project event' do
      expect(build(:project_created_event).present).to have_attributes(target_type_name: 'project')
    end

    it 'returns milestone for a milestone event' do
      expect(group_event.present).to have_attributes(target_type_name: 'milestone')
    end
  end

  describe '#note_target_type_name' do
    it 'returns design for an event on a comment on a design' do
      expect(build(:event, :commented, :for_design).present)
        .to have_attributes(note_target_type_name: 'design')
    end

    it 'returns nil for an event without a target' do
      expect(build(:event).present).to have_attributes(note_target_type_name: be_nil)
    end

    it 'returns issue for an issue comment event' do
      expect(build(:event, :commented, target: build(:note_on_issue)).present)
        .to have_attributes(note_target_type_name: 'issue')
    end
  end
end
