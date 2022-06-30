# frozen_string_literal: true

RSpec.shared_context 'repository disabled via project features' do
  before do
    project.project_feature.update_columns(
      # Disable merge_requests and builds as well, since merge_requests and
      # builds cannot have higher visibility than repository.
      merge_requests_access_level: ProjectFeature::DISABLED,
      builds_access_level: ProjectFeature::DISABLED,
      repository_access_level: ProjectFeature::DISABLED)
  end
end

RSpec.shared_context 'registry disabled via project features' do
  before do
    project.project_feature.update_columns(
      container_registry_access_level: ProjectFeature::DISABLED
    )
  end
end

RSpec.shared_context 'registry set to private via project features' do
  before do
    project.project_feature.update_columns(
      container_registry_access_level: ProjectFeature::PRIVATE
    )
  end
end
