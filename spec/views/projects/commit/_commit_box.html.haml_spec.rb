require 'spec_helper'

describe 'projects/commit/_commit_box.html.haml' do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    assign(:project, project)
    assign(:commit, project.commit)
    allow(view).to receive(:can_collaborate_with_project?).and_return(false)
  end

  it 'shows the commit SHA' do
    render

    expect(rendered).to have_text("#{Commit.truncate_sha(project.commit.sha)}")
  end

  it 'shows the last pipeline that ran for the commit' do
    create(:ci_pipeline, project: project, sha: project.commit.id, status: 'success')
    create(:ci_pipeline, project: project, sha: project.commit.id, status: 'canceled')
    third_pipeline = create(:ci_pipeline, project: project, sha: project.commit.id, status: 'failed')

    render

    expect(rendered).to have_text("Pipeline ##{third_pipeline.id} failed")
  end

  context 'viewing a commit' do
    context 'as a developer' do
      before do
        expect(view).to receive(:can_collaborate_with_project?).and_return(true)
      end

      it 'has a link to create a new tag' do
        render

        expect(rendered).to have_link('Tag')
      end
    end

    context 'as a non-developer' do
      before do
        expect(view).to receive(:can_collaborate_with_project?).and_return(false)
      end

      it 'does not have a link to create a new tag' do
        render

        expect(rendered).not_to have_link('Tag')
      end
    end
  end
end
