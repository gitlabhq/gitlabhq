require 'spec_helper'

describe 'projects/commit/_commit_box.html.haml' do
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

  context 'when there is a pipeline present' do
    context 'when there are multiple pipelines for a commit' do
      it 'shows the last pipeline' do
        create(:ci_pipeline, project: project, sha: project.commit.id, status: 'success')
        create(:ci_pipeline, project: project, sha: project.commit.id, status: 'canceled')
        third_pipeline = create(:ci_pipeline, project: project, sha: project.commit.id, status: 'failed')

        render

        expect(rendered).to have_text("Pipeline ##{third_pipeline.id} failed")
      end
    end

    context 'when pipeline for the commit is blocked' do
      let!(:pipeline) do
        create(:ci_pipeline, :blocked, project: project,
                                       sha: project.commit.id)
      end

      it 'shows correct pipeline description' do
        render

        expect(rendered).to have_text "Pipeline ##{pipeline.id} " \
                                      'waiting for manual action'
      end
    end
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
