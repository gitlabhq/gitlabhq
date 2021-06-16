# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetIssueIdForAllVersions do
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:designs) { table(:design_management_designs) }
  let(:designs_versions) { table(:design_management_designs_versions) }
  let(:versions) { table(:design_management_versions) }

  before do
    @project = projects.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce', namespace_id: 1)

    @issue_1 = issues.create!(description: 'first', project_id: @project.id)
    @issue_2 = issues.create!(description: 'second', project_id: @project.id)

    @design_1 = designs.create!(issue_id: @issue_1.id, filename: 'homepage-1.jpg', project_id: @project.id)
    @design_2 = designs.create!(issue_id: @issue_2.id, filename: 'homepage-2.jpg', project_id: @project.id)

    @version_1 = versions.create!(sha: 'foo')
    @version_2 = versions.create!(sha: 'bar')

    designs_versions.create!(version_id: @version_1.id, design_id: @design_1.id)
    designs_versions.create!(version_id: @version_2.id, design_id: @design_2.id)
  end

  it 'correctly sets issue_id' do
    expect(versions.where(issue_id: nil).count).to eq(2)

    migrate!

    expect(versions.where(issue_id: nil).count).to eq(0)
    expect(versions.find(@version_1.id).issue_id).to eq(@issue_1.id)
    expect(versions.find(@version_2.id).issue_id).to eq(@issue_2.id)
  end
end
