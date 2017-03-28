class NotifyPreview < ActionMailer::Preview
  def pipeline_success_email
    pipeline = Ci::Pipeline.last
    Notify.pipeline_success_email(pipeline, pipeline.user.try(:email))
  end

  def pipeline_failed_email
    pipeline = Ci::Pipeline.last
    Notify.pipeline_failed_email(pipeline, pipeline.user.try(:email))
  end
end
