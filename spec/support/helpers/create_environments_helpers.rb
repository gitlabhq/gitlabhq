# frozen_string_literal: true

module CreateEnvironmentsHelpers
  def create_review_app(user, project, ref)
    common = { project: project, ref: ref, user: user }
    pipeline = create(:ci_pipeline, **common)
    start_review = create(:ci_build, :start_review_app, :success, **common, pipeline: pipeline)
    stop_review = create(:ci_build, :stop_review_app, :manual, **common, pipeline: pipeline)
    environment = create(:environment, :auto_stoppable, project: project, name: ref)
    create(:deployment, :success, **common,
      on_stop: stop_review.name, deployable: start_review, environment: environment)
  end
end
