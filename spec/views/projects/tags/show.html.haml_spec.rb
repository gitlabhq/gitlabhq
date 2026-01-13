# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/tags/show.html.haml', feature_category: :source_code_management do
  include RenderedHtml

  let_it_be(:project) { create(:project, :repository) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- necessary to use create
  let_it_be(:git_tag) { project.repository.tags.last }

  let(:user) { build(:user) }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    assign(:tag, git_tag)

    allow(view).to receive(:current_user).and_return(user)
  end

  context 'for pipeline status' do
    it 'renders the pipeline status icon if pipeline is present' do
      create(:ci_pipeline, # rubocop:disable RSpec/FactoryBot/AvoidCreate -- necessary to use create
        project: project,
        ref: git_tag.name,
        sha: project.commit(git_tag.name).sha,
        status: :success)
      pipeline_statuses = Ci::CommitStatusesFinder.new(project, project.repository, project.namespace.owner,
        [git_tag]).execute
      assign(:pipeline_status, pipeline_statuses[git_tag.name])
      render

      expect(rendered).to have_css('[data-testid="status_success_borderless-icon"]')
    end

    it 'does not render the pipeline status icon if no pipelines exist' do
      render

      expect(rendered).not_to have_css('[data-testid="status_success_borderless-icon"]')
    end
  end

  context 'for signature badge' do
    it 'renders the signature badge if present' do
      render

      expect(rendered).to have_css('.signature-badge')
    end

    it 'does not render the signature badge if absent' do
      allow(git_tag).to receive_messages(has_signature?: false, signature: nil)
      render

      expect(rendered).not_to have_css('.signature-badge')
    end
  end

  context 'for create/edit release button' do
    let_it_be(:release) { build(:release, project: project, tag: 'v1.1.0') }

    it 'edit release button is rendered when release is present and user has permission' do
      allow(view).to receive(:can?).with(user, :admin_tag, project).and_return(true)
      assign(:release, release)
      render

      expect(rendered).to have_link('Edit release')
    end

    it 'create release button is rendered when release is not present but user has permission' do
      allow(view).to receive(:can?).with(user, :admin_tag, project).and_return(true)
      assign(:release, nil)
      render

      expect(rendered).to have_link('Create release')
    end

    it 'neither create or edit release button are rendered when user does not have permission' do
      allow(view).to receive(:can?).with(user, :admin_tag, project).and_return(false)
      assign(:release, release)
      render

      expect(rendered).not_to have_link('Create release')
      expect(rendered).not_to have_link('Edit release')
    end
  end

  context 'for remove tag button' do
    it 'is rendered when user has permission' do
      allow(view).to receive(:can?).with(user, :admin_tag, project).and_return(true)
      render

      expect(rendered).to have_css('button[title="Delete tag"]')
    end

    it 'is not rendered when user does not have permission' do
      allow(view).to receive(:can?).with(user, :admin_tag, project).and_return(false)
      render

      expect(rendered).not_to have_css('button[title="Delete tag"]')
    end
  end
end
