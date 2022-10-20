# frozen_string_literal: true

module ProjectHelpers
  def update_feature_access_level(project, access_level, additional_params = {})
    features = ProjectFeature::FEATURES.dup
    features.delete(:pages)
    params = features.each_with_object({}) { |feature, h| h["#{feature}_access_level"] = access_level }

    project.update!(params.merge(additional_params))
  end

  def create_project_with_statistics(namespace = nil, with_data: false, size_multiplier: 1)
    project = namespace.present? ? create(:project, namespace: namespace) : create(:project)
    project.tap do |p|
      create(:project_statistics, project: p, with_data: with_data, size_multiplier: size_multiplier)
    end
  end

  def grace_months_after_deletion_notification
    (::Gitlab::CurrentSettings.inactive_projects_delete_after_months -
      ::Gitlab::CurrentSettings.inactive_projects_send_warning_email_after_months).months
  end

  def deletion_date
    Date.parse(grace_months_after_deletion_notification.from_now.to_s).to_s
  end
end
