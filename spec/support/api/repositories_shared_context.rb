shared_context 'disabled repository' do
  before do
    project.project_feature.update_attributes!(
      repository_access_level: ProjectFeature::DISABLED,
      merge_requests_access_level: ProjectFeature::DISABLED,
      builds_access_level: ProjectFeature::DISABLED
    )
    expect(project.feature_available?(:repository, current_user)).to be false
  end
end
