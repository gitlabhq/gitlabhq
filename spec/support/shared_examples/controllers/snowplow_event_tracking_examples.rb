# frozen_string_literal: true
#
# Requires a context containing:
# - subject
# - feature_flag_name
# - category
# - action
# - namespace
# Optionaly, the context can contain:
# - project
# - property
# - user
# - label
# - **extra

shared_examples 'Snowplow event tracking' do
  it 'is not emitted if FF is disabled' do
    stub_feature_flags(feature_flag_name => false)

    subject

    expect_no_snowplow_event(category: category, action: action)
  end

  it 'is emitted' do
    extra ||= {}

    params = {
      category: category,
      action: action,
      namespace: namespace,
      user: try(:user),
      project: try(:project),
      label: try(:label),
      property: try(:property),
      **extra
    }.compact

    subject

    expect_snowplow_event(**params)
  end
end
