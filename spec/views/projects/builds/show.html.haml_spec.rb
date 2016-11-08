require 'spec_helper'

describe 'projects/builds/show' do
  include Devise::Test::ControllerHelpers

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

  describe 'environment info in build view' do
    context 'build with latest deployment' do
      let(:build) { create(:ci_build, :success, environment: 'staging') }
      let(:environment) { create(:environment, name: 'staging') }
      let!(:deployment) { create(:deployment, deployable: build) }

      it 'shows deployment message' do
        expect(rendered).to have_css('.environment-information', text: 'This build is the most recent deployment')
      end
    end

    context 'build with outdated deployment' do
      let(:build) { create(:ci_build, :success, environment: 'staging', pipeline: pipeline) }
      let(:environment) { create(:environment, name: 'staging', project: project) }
      let!(:deployment) { create(:deployment, environment: environment, deployable: build) }
      let!(:newer_deployment) { create(:deployment, environment: environment, deployable: build) }

      before do
        assign(:build, build)
        assign(:project, project)

        allow(view).to receive(:can?).and_return(true)
        render
      end

      it 'shows deployment message' do
        expect(rendered).to have_css('.environment-information', text: "This build is an out-of-date deployment to #{environment.name}. View the most recent deployment #1")
      end
    end

    context 'build failed to deploy' do
      let(:build) { create(:ci_build, :failed, environment: 'staging') }
      let!(:environment) { create(:environment, name: 'staging') }
    end

    context 'build will deploy' do
      let(:build) { create(:ci_build, :running, environment: 'staging') }
      let!(:environment) { create(:environment, name: 'staging') }
    end

    context 'build that failed to deploy and environment has not been created' do
      let(:build) { create(:ci_build, :failed, environment: 'staging') }
    end

    context 'build that will deploy and environment has not been created' do
      let(:build) { create(:ci_build, :running, environment: 'staging') }
      let!(:environment) { create(:environment, name: 'staging') }
    end
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
      expect(rendered).to have_css('.js-build-variable', visible: false, text: 'TRIGGER_KEY_1')
      expect(rendered).to have_css('.js-build-variable', visible: false, text: 'TRIGGER_KEY_2')
      expect(rendered).to have_css('.js-build-value', visible: false, text: 'TRIGGER_VALUE_1')
      expect(rendered).to have_css('.js-build-value', visible: false, text: 'TRIGGER_VALUE_2')
    end
  end
end
