require 'spec_helper'

describe 'projects/_last_commit', :view do
  let(:project) { create(:project, :repository) }

  context 'when there is a pipeline present for the commit' do
    context 'when pipeline is blocked' do
      let!(:pipeline) do
        create(:ci_pipeline, :blocked, project: project,
                                       sha: project.commit.id)
      end

      it 'shows correct pipeline badge' do
        render 'projects/last_commit', commit: project.commit,
                                       project: project,
                                       ref: :master

        expect(rendered).to have_text "blocked #{project.commit.short_id}"
      end
    end
  end
end
