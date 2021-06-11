# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateTimestampSoftwarelicensespolicy do
  let(:software_licenses_policy) { table(:software_license_policies) }
  let(:projects) { table(:projects) }
  let(:licenses) { table(:software_licenses) }

  before do
    projects.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce', namespace_id: 1)
    licenses.create!(name: 'MIT')
    software_licenses_policy.create!(project_id: projects.first.id, software_license_id: licenses.first.id, created_at: nil, updated_at: nil)
  end

  it 'creates timestamps' do
    migrate!

    expect(software_licenses_policy.first.created_at).to be_present
    expect(software_licenses_policy.first.updated_at).to be_present
  end
end
