# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/commits/show.html.haml' do
  let(:project) { create(:project, :repository) }
  let(:commits) { [project.commit] }
  let(:path) { 'path/to/doc.md' }

  before do
    assign(:project, project)
    assign(:id, path)
    assign(:repository, project.repository)
    assign(:commits, commits)
    assign(:hidden_commit_count, 0)

    controller.params[:controller] = 'projects/commits'
    controller.params[:action] = 'show'
    controller.params[:namespace_id] = project.namespace.to_param
    controller.params[:project_id] = project.to_param

    allow(view).to receive(:current_user).and_return(nil)
    allow(view).to receive(:namespace_project_signatures_path).and_return("/")
  end

  context 'tree controls' do
    before do
      render
    end

    it 'renders atom feed button with matching path' do
      expect(rendered).to have_link(href: "#{project_commits_path(project, path)}?format=atom")
    end
  end
end
