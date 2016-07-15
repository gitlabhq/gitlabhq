require 'spec_helper'

describe 'projects/builds/show' do
  include Devise::TestHelpers

  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  before do
    assign(:build, build)
    assign(:project, project)

    allow(view).to receive(:can?).and_return(true)
  end

  context 'when build is running' do
    before do
      build.run!
      render
    end

    it 'does not show retry button' do
      expect(rendered).not_to have_link('Retry')
    end
  end

  context 'when build is not running' do
    before do
      build.success!
      render
    end

    it 'shows retry button' do
      expect(rendered).to have_link('Retry')
    end
  end

  describe 'projects/builds/show/commit title' do
    let(:commit_title) {build.project.commit.title}
    
    it 'shows commit title' do
      within('p.build-light-text.append-bottom-0') do
        expect(rendered).to have_content(commit_title)
      end
    end 
  end
end
