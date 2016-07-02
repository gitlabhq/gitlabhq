require 'spec_helper'

describe 'projects/builds/show' do
  include Devise::TestHelpers

  let(:build) { create(:ci_build) }
  let(:project) { build.project }

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
end
