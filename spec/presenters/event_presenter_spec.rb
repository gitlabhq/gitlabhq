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

    it 'returns the issue_type for issue events' do
      expect(build(:event, :for_issue, :created).present).to have_attributes(target_type_name: 'issue')
    end

    it 'returns the issue_type for work item events' do
      expect(build(:event, :for_work_item, :created).present).to have_attributes(target_type_name: 'task')
    end
  end

  describe '#note_target_type_name' do
    it 'returns design for an event on a comment on a design' do
      expect(build(:event, :commented, :for_design).present)
        .to have_attributes(note_target_type_name: 'design')
    end

    it 'returns wiki page for an event on a comment on a wiki page' do
      expect(build(:event, :commented, :for_wiki_page_note).present)
        .to have_attributes(note_target_type_name: 'wiki page')
    end

    it 'returns nil for an event without a target' do
      expect(build(:event).present).to have_attributes(note_target_type_name: be_nil)
    end

    it 'returns issue for an issue comment event' do
      expect(build(:event, :commented, target: build(:note_on_issue)).present)
        .to have_attributes(note_target_type_name: 'issue')
    end
  end

  describe '#push_activity_description' do
    subject { event.present.push_activity_description }

    context 'when event is a regular event' do
      let(:event) { build(:event, project: project) }

      it { is_expected.to be_nil }
    end

    context 'when event is a push event' do
      let!(:push_event_payload) { build(:push_event_payload, event: event, ref_count: ref_count) }
      let(:event) { build(:push_event, project: project) }

      context 'when it is an individual event' do
        let(:ref_count) { nil }

        it { is_expected.to eq 'pushed to branch' }
      end

      context 'when it is a batch event' do
        let(:ref_count) { 1 }

        it { is_expected.to eq 'pushed to 1 branch' }
      end
    end
  end

  describe '#batch_push?' do
    subject { event.present.batch_push? }

    context 'when event is a regular event' do
      let(:event) { build(:event, project: project) }

      it { is_expected.to be_falsey }
    end

    context 'when event is a push event' do
      let!(:push_event_payload) { build(:push_event_payload, event: event, ref_count: ref_count) }
      let(:event) { build(:push_event, project: project) }

      context 'when it is an individual event' do
        let(:ref_count) { nil }

        it { is_expected.to be_falsey }
      end

      context 'when it is a batch event' do
        let(:ref_count) { 1 }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#linked_to_reference?' do
    subject { event.present.linked_to_reference? }

    context 'when event is a regular event' do
      let(:event) { build(:event, project: project) }

      it { is_expected.to be_falsey }
    end

    context 'when event is a push event' do
      let!(:push_event_payload) { build(:push_event_payload, event: event, ref: ref, ref_type: ref_type) }
      let(:ref) { 'master' }
      let(:ref_type) { :branch }

      context 'when event belongs to group' do
        let(:event) { build(:push_event, group: group) }

        it { is_expected.to be_falsey }
      end

      context 'when event belongs to project' do
        let(:event) { build(:push_event, project: project) }

        it { is_expected.to be_falsey }

        context 'when matching tag exists' do
          let(:ref_type) { :tag }

          before do
            allow(project.repository).to receive(:tag_exists?).with(ref).and_return(true)
          end

          it { is_expected.to be_truthy }
        end

        context 'when matching branch exists' do
          before do
            allow(project.repository).to receive(:branch_exists?).with(ref).and_return(true)
          end

          it { is_expected.to be_truthy }
        end
      end
    end
  end
end
