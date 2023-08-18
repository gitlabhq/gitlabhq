# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/commits/show.html.haml' do
  let_it_be(:project) { create(:project, :repository) }

  let(:commits) { [commit] }
  let(:commit) { project.commit }
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

  context 'commits date headers' do
    let(:user) { build(:user, timezone: timezone) }
    let(:committed_date) { Time.find_zone('UTC').parse('2023-01-01') }

    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(commit).to receive(:committed_date).and_return(committed_date)

      render
    end

    context 'when timezone is UTC' do
      let(:timezone) { 'UTC' }

      it "renders commit date header in user's timezone" do
        expect(rendered).to include('data-day="2023-01-01"')
      end
    end

    context 'when timezone is UTC-6' do
      let(:timezone) { 'America/Mexico_City' }

      it "renders commit date header in user's timezone" do
        expect(rendered).to include('data-day="2022-12-31"')
      end
    end
  end
end
