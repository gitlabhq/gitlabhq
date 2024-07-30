# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'shared/_label_row.html.haml' do
  let_it_be(:group) { create(:group) }

  let(:label) { build_stubbed(:group_label, group: group).present(issuable_subject: group) }

  before do
    allow(view).to receive(:label) { label }
  end

  context 'with a project context' do
    let_it_be(:project) { create(:project, group: group) }

    let(:label) { build_stubbed(:label, project: project).present(issuable_subject: project) }

    before do
      assign(:project, label.project)

      render
    end

    it 'has label title' do
      expect(rendered).to have_text(label.title)
    end

    it 'has a linked label title' do
      expect(rendered).to have_link(label.title)
    end

    it 'has Issues link' do
      expect(rendered).to have_link('Issues')
    end

    it 'has Merge request link' do
      expect(rendered).to have_link('Merge requests')
    end

    it 'shows the path from where the label was created' do
      expect(rendered).to have_text(project.full_name)
    end
  end

  context 'with a subgroup context' do
    let_it_be(:subgroup) { create(:group, parent: group) }

    let(:label) { build_stubbed(:group_label, group: subgroup).present(issuable_subject: subgroup) }

    before do
      assign(:group, label.group)

      render
    end

    it 'has label title' do
      expect(rendered).to have_text(label.title)
    end

    it 'has a linked label title' do
      expect(rendered).to have_link(label.title)
    end

    it 'has Issues link' do
      expect(rendered).to have_link('Issues')
    end

    it 'has Merge request link' do
      expect(rendered).to have_link('Merge requests')
    end

    it 'shows the path from where the label was created' do
      expect(rendered).to have_text(subgroup.full_name)
    end
  end

  context 'with a group context' do
    before do
      assign(:group, label.group)

      render
    end

    it 'has label title' do
      expect(rendered).to have_text(label.title)
    end

    it 'has a linked label title' do
      expect(rendered).to have_link(label.title)
    end

    it 'has Issues link' do
      expect(rendered).to have_link('Issues')
    end

    it 'has Merge request link' do
      expect(rendered).to have_link('Merge requests')
    end
  end

  context 'with an admin context' do
    before do
      render
    end

    it 'has label title' do
      expect(rendered).to have_text(label.title)
    end

    it 'has a linked label title' do
      expect(rendered).to have_link(label.title)
    end

    it 'does not show Issues link' do
      expect(rendered).not_to have_link('Issues')
    end

    it 'does not show Merge request link' do
      expect(rendered).not_to have_link('Merge requests')
    end
  end
end
