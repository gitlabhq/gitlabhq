# frozen_string_literal: true

require 'spec_helper'

describe 'projects/tags/index.html.haml' do
  let(:project)  { create(:project, :repository) }
  let(:tags)     { TagsFinder.new(project.repository, {}).execute }
  let(:git_tag)  { project.repository.tags.last }
  let(:release)  { create(:release, project: project, sha: git_tag.target_commit.sha) }
  let(:pipeline) { create(:ci_pipeline, :success, project: project, ref: git_tag.name, sha: release.sha) }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    assign(:releases, project.releases)
    assign(:tags, Kaminari.paginate_array(tags).page(0))
    assign(:tags_pipelines, { git_tag.name => pipeline })

    allow(view).to receive(:current_ref).and_return('master')
    allow(view).to receive(:current_user).and_return(project.namespace.owner)
  end

  it 'defaults sort dropdown toggle to last updated' do
    render
    expect(rendered).to have_button('Last updated')
  end

  it 'renders links to the Releases page for tags associated with a release' do
    render
    expect(rendered).to have_link(release.name, href: project_releases_path(project, anchor: release.tag))
  end

  context 'when the most recent build for a tag has artifacts' do
    let!(:build) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

    it 'renders the Artifacts section in the download list' do
      render
      expect(rendered).to have_selector('li', text: 'Artifacts')
    end

    it 'renders artifact download links' do
      render
      expect(rendered).to have_link(href: latest_succeeded_project_artifacts_path(project, "#{pipeline.ref}/download", job: 'test'))
    end
  end

  context 'when the most recent build for a tag has expired artifacts' do
    let!(:build) { create(:ci_build, :success, :expired, :artifacts, pipeline: pipeline) }

    it 'does not render the Artifacts section in the download list' do
      render
      expect(rendered).not_to have_selector('li', text: 'Artifacts')
    end

    it 'does not render artifact download links' do
      render
      expect(rendered).not_to have_link(href: latest_succeeded_project_artifacts_path(project, "#{pipeline.ref}/download", job: 'test'))
    end
  end
end
