require 'spec_helper'

describe 'projects/builds/show' do
  include Devise::TestHelpers

  let(:project) { create(:project) }
  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id)
  end
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

  describe 'commit title in sidebar' do
    let(:commit_title) { project.commit.title }

    it 'shows commit title and not show commit message' do
      render

      expect(rendered).to have_css('p.build-light-text.append-bottom-0',
        text: /\A\n#{Regexp.escape(commit_title)}\n\Z/)
    end
  end

  describe 'shows trigger variables in sidebar' do
    let(:trigger_request) { create(:ci_trigger_request_with_variables, pipeline: pipeline) }

    before do
      build.trigger_request = trigger_request
      render
    end

    it 'shows trigger variables in separate lines' do
      expect(rendered).to have_css('.js-build-variable', visible: false, text: variable_regexp_key('TRIGGER_KEY_1'))
      expect(rendered).to have_css('.js-build-variable', visible: false, text: variable_regexp_key('TRIGGER_KEY_2'))
      expect(rendered).to have_css('.js-build-value', visible: false, text: variable_regexp_value('TRIGGER_VALUE_1'))
      expect(rendered).to have_css('.js-build-value', visible: false, text: variable_regexp_value('TRIGGER_VALUE_2'))
    end
  end

  private

  def variable_regexp_key(key)
    /\A#{Regexp.escape("#{key}")}\Z/
  end
 
  def variable_regexp_value(value)
    /\A#{Regexp.escape("#{value}")}\Z/
  end
end
