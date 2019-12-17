# frozen_string_literal: true

require 'spec_helper'

describe LabelPresenter do
  include Gitlab::Routing.url_helpers

  set(:group) { create(:group) }
  set(:project) { create(:project, group: group) }
  let(:label) { build_stubbed(:label, project: project).present(issuable_subject: project) }
  let(:group_label) { build_stubbed(:group_label, group: group).present(issuable_subject: project) }

  describe '#edit_path' do
    context 'with group label' do
      subject { group_label.edit_path }

      it { is_expected.to eq(edit_group_label_path(group, group_label)) }
    end

    context 'with project label' do
      subject { label.edit_path }

      it { is_expected.to eq(edit_project_label_path(project, label)) }
    end
  end

  describe '#destroy_path' do
    context 'with group label' do
      subject { group_label.destroy_path }

      it { is_expected.to eq(group_label_path(group, group_label)) }
    end

    context 'with project label' do
      subject { label.destroy_path }

      it { is_expected.to eq(project_label_path(project, label)) }
    end
  end

  describe '#filter_path' do
    context 'with group as context subject' do
      let(:label_in_group) { build_stubbed(:label, project: project).present(issuable_subject: group) }

      subject { label_in_group.filter_path }

      it { is_expected.to eq(issues_group_path(group, label_name: [label_in_group.title])) }
    end

    context 'with project as context subject' do
      subject { label.filter_path }

      it { is_expected.to eq(namespace_project_issues_path(group, project, label_name: [label.title])) }
    end
  end

  describe '#can_subscribe_to_label_in_different_levels?' do
    it 'returns true for group labels in project context' do
      expect(group_label.can_subscribe_to_label_in_different_levels?).to be_truthy
    end

    it 'returns false for project labels in project context' do
      expect(label.can_subscribe_to_label_in_different_levels?).to be_falsey
    end
  end

  describe '#project_label?' do
    context 'with group label' do
      subject { group_label.project_label? }

      it { is_expected.to be_falsey }
    end

    context 'with project label' do
      subject { label.project_label? }

      it { is_expected.to be_truthy }
    end
  end

  describe '#subject_name' do
    context 'with group label' do
      subject { group_label.subject_name }

      it { is_expected.to eq(group_label.group.name) }
    end

    context 'with project label' do
      subject { label.subject_name }

      it { is_expected.to eq(label.project.name) }
    end
  end
end
