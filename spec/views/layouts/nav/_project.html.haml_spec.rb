require 'spec_helper'

describe 'layouts/nav/_project' do
  describe 'container registry tab' do
    before do
      stub_container_registry_config(enabled: true)

      assign(:project, create(:project))
      allow(view).to receive(:current_ref).and_return('master')

      allow(view).to receive(:can?).and_return(true)
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

      expect(rendered).to have_css('.active', count: 1)
    end

    it 'highlights container registry tab only' do
      render

      expect(rendered).to have_css('.active', text: 'Registry')
    end
  end
end
