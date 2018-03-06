require 'spec_helper'

describe 'layouts/nav/sidebar/_project' do
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    allow(view).to receive(:current_ref).and_return('master')

    allow(view).to receive(:can?).and_return(true)
  end

  describe 'issue boards' do
    it 'has board tab' do
      render

      expect(rendered).to have_css('a[title="Boards"]')
    end

    it 'has board tab when multiple issue boards is not available' do
      allow(License).to receive(:feature_available?).and_call_original
      allow(License).to receive(:feature_available?).with(:multiple_project_issue_boards) { false }

      render

      expect(rendered).to have_css('a[title="Board"]')
    end
  end

  describe 'container registry tab' do
    before do
      stub_container_registry_config(enabled: true)

      allow(controller).to receive(:controller_name)
        .and_return('repositories')
      allow(controller).to receive(:controller_path)
        .and_return('projects/registry/repositories')
    end

    it 'has both Registry and Repository tabs' do
      render

      expect(rendered).to have_text 'Repository'
      expect(rendered).to have_text 'Registry'
    end

    it 'highlights only one tab' do
      render

      expect(rendered).to have_css('.active', count: 2)
    end

    it 'highlights container registry tab only' do
      render

      expect(rendered).to have_css('.active', text: 'Registry')
    end
  end
end
