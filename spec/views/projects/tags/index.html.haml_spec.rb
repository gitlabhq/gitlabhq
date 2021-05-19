# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/tags/index.html.haml' do
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

  context 'build stats' do
    let(:tag) { 'v1.0.0' }
    let(:page) { Capybara::Node::Simple.new(rendered) }

    it 'shows build status or placeholder when pipelines present' do
      create(:ci_pipeline,
        project: project,
        ref: tag,
        sha: project.commit(tag).sha,
        status: :success)
      assign(:tag_pipeline_statuses, Ci::CommitStatusesFinder.new(project, project.repository, project.namespace.owner, tags).execute)

      render

      expect(page.find('.tags .content-list li', text: tag)).to have_css 'a.ci-status-icon-success'
      expect(page.all('.tags .content-list li')).to all(have_css('svg.s24'))
    end

    it 'shows no build status or placeholder when no pipelines present' do
      render

      expect(page.all('.tags .content-list li')).not_to have_css 'svg.s24'
    end

    it 'shows no build status or placeholder when pipelines are private' do
      project.project_feature.update!(builds_access_level: ProjectFeature::PRIVATE)
      assign(:tag_pipeline_statuses, Ci::CommitStatusesFinder.new(project, project.repository, build(:user), tags).execute)

      render

      expect(page.all('.tags .content-list li')).not_to have_css 'svg.s24'
    end
  end
end
