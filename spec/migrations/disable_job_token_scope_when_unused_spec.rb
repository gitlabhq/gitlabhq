# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DisableJobTokenScopeWhenUnused, :suppress_gitlab_schemas_validate_connection do
  let(:ci_cd_settings) { table(:project_ci_cd_settings) }
  let(:links) { table(:ci_job_token_project_scope_links) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let(:namespace) { namespaces.create!(name: 'test', path: 'path', type: 'Group') }

  let(:project_with_used_scope) { projects.create!(namespace_id: namespace.id) }
  let!(:used_scope_settings) { ci_cd_settings.create!(project_id: project_with_used_scope.id, job_token_scope_enabled: true) }
  let(:target_project) { projects.create!(namespace_id: namespace.id) }
  let!(:link) { links.create!(source_project_id: project_with_used_scope.id, target_project_id: target_project.id) }

  let(:project_with_unused_scope) { projects.create!(namespace_id: namespace.id) }
  let!(:unused_scope_settings) { ci_cd_settings.create!(project_id: project_with_unused_scope.id, job_token_scope_enabled: true) }

  let(:project_with_disabled_scope) { projects.create!(namespace_id: namespace.id) }
  let!(:disabled_scope_settings) { ci_cd_settings.create!(project_id: project_with_disabled_scope.id, job_token_scope_enabled: false) }

  describe '#up' do
    it 'sets job_token_scope_enabled to false for projects not having job token scope configured' do
      migrate!

      expect(unused_scope_settings.reload.job_token_scope_enabled).to be_falsey
    end

    it 'keeps the scope enabled for projects that are using it' do
      migrate!

      expect(used_scope_settings.reload.job_token_scope_enabled).to be_truthy
    end

    it 'keeps the scope disabled for projects having it disabled' do
      migrate!

      expect(disabled_scope_settings.reload.job_token_scope_enabled).to be_falsey
    end
  end
end
