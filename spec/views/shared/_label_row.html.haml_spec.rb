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

    it 'has a non-linked label title' do
      expect(rendered).not_to have_css('a', text: label.title)
    end

    it "has Issues link" do
      expect(rendered).to have_css('a', text: 'Issues')
    end

    it "has Merge request link" do
      expect(rendered).to have_css('a', text: 'Merge requests')
    end

    it "shows the path from where the label was created" do
      expect(rendered).to have_css('.label-badge', text: project.full_name)
    end
  end

  context 'with a group context' do
    before do
      assign(:group, label.group)

      render
    end

    it 'has a non-linked label title' do
      expect(rendered).not_to have_css('a', text: label.title)
    end

    it "has Issues link" do
      expect(rendered).to have_css('a', text: 'Issues')
    end

    it "has Merge request link" do
      expect(rendered).to have_css('a', text: 'Merge requests')
    end

    it "does not show a path from where the label was created" do
      expect(rendered).not_to have_css('.label-badge')
    end
  end

  context 'with an admin context' do
    before do
      render
    end

    it 'has a non-linked label title' do
      expect(rendered).not_to have_css('a', text: label.title)
    end

    it "does not show Issues link" do
      expect(rendered).not_to have_css('a', text: 'Issues')
    end

    it "does not show Merge request link" do
      expect(rendered).not_to have_css('a', text: 'Merge requests')
    end

    it "does not show a path from where the label was created" do
      expect(rendered).not_to have_css('.label-badge')
    end
  end
end
