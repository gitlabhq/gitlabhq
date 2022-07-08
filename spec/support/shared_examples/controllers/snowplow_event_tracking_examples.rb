# frozen_string_literal: true
#
# Requires a context containing:
# - subject
# - project
# - feature_flag_name
# - category
# - action
# - namespace
# - user

shared_examples 'Snowplow event tracking' do
  let(:label) { nil }

  it 'is not emitted if FF is disabled' do
    stub_feature_flags(feature_flag_name => false)

    subject

    expect_no_snowplow_event
  end

  it 'is emitted' do
    params = {
      category: category,
      action: action,
      namespace: namespace,
      user: user,
      project: project,
      label: label
    }.compact

    subject

    expect_snowplow_event(**params)
  end
end
