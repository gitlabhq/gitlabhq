require 'spec_helper'

describe 'projects/jobs/show' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:builds) { project.builds.present(current_user: user) }

  let(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit.id)
  end

  before do
    assign(:build, build.present)
    assign(:project, project)
    assign(:builds, builds)

    allow(view).to receive(:can?).and_return(true)
  end

  describe 'environment info in job view' do
    context 'job with latest deployment' do
      let(:build) do
        create(:ci_build, :success, :trace_artifact, environment: 'staging')
      end

      before do
        create(:environment, name: 'staging')
        create(:deployment, deployable: build)
      end

      it 'shows deployment message' do
        expected_text = 'This job is the most recent deployment'
        render

        expect(rendered).to have_css(
          '.environment-information', text: expected_text)
      end
    end

    context 'job with outdated deployment' do
      let(:build) do
        create(:ci_build, :success, :trace_artifact, environment: 'staging', pipeline: pipeline)
      end

      let(:second_build) do
        create(:ci_build, :success, :trace_artifact, environment: 'staging', pipeline: pipeline)
      end

      let(:environment) do
        create(:environment, name: 'staging', project: project)
      end

      let!(:first_deployment) do
        create(:deployment, environment: environment, deployable: build)
      end

      let!(:second_deployment) do
        create(:deployment, environment: environment, deployable: second_build)
      end

      it 'shows deployment message' do
        expected_text = 'This job is an out-of-date deployment ' \
          "to staging.\nView the most recent deployment ##{second_deployment.iid}."
        render

        expect(rendered).to have_css('.environment-information', text: expected_text)
      end
    end

    context 'job failed to deploy' do
      let(:build) do
        create(:ci_build, :failed, :trace_artifact, environment: 'staging', pipeline: pipeline)
      end

      let!(:environment) do
        create(:environment, name: 'staging', project: project)
      end

      it 'shows deployment message' do
        expected_text = 'The deployment of this job to staging did not succeed.'
        render

        expect(rendered).to have_css(
          '.environment-information', text: expected_text)
      end
    end

    context 'job will deploy' do
      let(:build) do
        create(:ci_build, :running, :trace_live, environment: 'staging', pipeline: pipeline)
      end

      context 'when environment exists' do
        let!(:environment) do
          create(:environment, name: 'staging', project: project)
        end

        it 'shows deployment message' do
          expected_text = 'This job is creating a deployment to staging'
          render

          expect(rendered).to have_css(
            '.environment-information', text: expected_text)
        end

        context 'when it has deployment' do
          let!(:deployment) do
            create(:deployment, environment: environment)
          end

          it 'shows that deployment will be overwritten' do
            expected_text = 'This job is creating a deployment to staging'
            render

            expect(rendered).to have_css(
              '.environment-information', text: expected_text)
            expect(rendered).to have_css(
              '.environment-information', text: 'latest deployment')
          end
        end
      end

      context 'when environment does not exist' do
        it 'shows deployment message' do
          expected_text = 'This job is creating a deployment to staging'
          render

          expect(rendered).to have_css(
            '.environment-information', text: expected_text)
          expect(rendered).not_to have_css(
            '.environment-information', text: 'latest deployment')
        end
      end
    end

    context 'job that failed to deploy and environment has not been created' do
      let(:build) do
        create(:ci_build, :failed, :trace_artifact, environment: 'staging', pipeline: pipeline)
      end

      let!(:environment) do
        create(:environment, name: 'staging', project: project)
      end

      it 'shows deployment message' do
        expected_text = 'The deployment of this job to staging did not succeed'
        render

        expect(rendered).to have_css(
          '.environment-information', text: expected_text)
      end
    end

    context 'job that will deploy and environment has not been created' do
      let(:build) do
        create(:ci_build, :running, :trace_live, environment: 'staging', pipeline: pipeline)
      end

      let!(:environment) do
        create(:environment, name: 'staging', project: project)
      end

      it 'shows deployment message' do
        expected_text = 'This job is creating a deployment to staging'
        render

        expect(rendered).to have_css(
          '.environment-information', text: expected_text)
        expect(rendered).not_to have_css(
          '.environment-information', text: 'latest deployment')
      end
    end
  end

  context 'when job is running' do
    let(:build) { create(:ci_build, :trace_live, :running, pipeline: pipeline) }

    before do
      render
    end

    it 'does not show retry button' do
      expect(rendered).not_to have_link('Retry')
    end

    it 'does not show New issue button' do
      expect(rendered).not_to have_link('New issue')
    end
  end
end
