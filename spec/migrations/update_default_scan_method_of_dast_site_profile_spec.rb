# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateDefaultScanMethodOfDastSiteProfile, feature_category: :dynamic_application_security_testing do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:dast_sites) { table(:dast_sites) }
  let(:dast_site_profiles) { table(:dast_site_profiles) }

  before do
    namespace = namespaces.create!(name: 'test', path: 'test')
    project = projects.create!(id: 12, namespace_id: namespace.id, name: 'gitlab', path: 'gitlab')
    dast_site = dast_sites.create!(id: 1, url: 'https://www.gitlab.com', project_id: project.id)

    dast_site_profiles.create!(
      id: 1,
      project_id: project.id,
      dast_site_id: dast_site.id,
      name: "#{FFaker::Product.product_name.truncate(192)} #{SecureRandom.hex(4)} - 0",
      scan_method: 0,
      target_type: 0
    )

    dast_site_profiles.create!(
      id: 2,
      project_id: project.id,
      dast_site_id: dast_site.id,
      name: "#{FFaker::Product.product_name.truncate(192)} #{SecureRandom.hex(4)} - 1",
      scan_method: 0,
      target_type: 1
    )
  end

  it 'updates the scan_method to 1 for profiles with target_type 1' do
    migrate!

    expect(dast_site_profiles.where(scan_method: 1).count).to eq 1
    expect(dast_site_profiles.where(scan_method: 0).count).to eq 1
  end
end
