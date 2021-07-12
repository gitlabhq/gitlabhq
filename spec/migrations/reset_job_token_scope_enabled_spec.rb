# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ResetJobTokenScopeEnabled do
  let(:settings) { table(:project_ci_cd_settings) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project_1) { projects.create!(name: 'proj-1', path: 'gitlab-org', namespace_id: namespace.id)}
  let(:project_2) { projects.create!(name: 'proj-2', path: 'gitlab-org', namespace_id: namespace.id)}

  before do
    settings.create!(id: 1, project_id: project_1.id, job_token_scope_enabled: true)
    settings.create!(id: 2, project_id: project_2.id, job_token_scope_enabled: false)
  end

  it 'migrates job_token_scope_enabled to be always false' do
    expect { migrate! }
      .to change { settings.where(job_token_scope_enabled: false).count }
      .from(1).to(2)
  end
end
