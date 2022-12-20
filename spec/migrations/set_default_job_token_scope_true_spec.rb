# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetDefaultJobTokenScopeTrue, schema: 20210819153805, feature_category: :continuous_integration do
  let(:ci_cd_settings) { table(:project_ci_cd_settings) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let(:namespace) { namespaces.create!(name: 'test', path: 'path', type: 'Group') }
  let(:project) { projects.create!(namespace_id: namespace.id) }

  describe '#up' do
    it 'sets the job_token_scope_enabled default to true' do
      described_class.new.up

      settings = ci_cd_settings.create!(project_id: project.id)

      expect(settings.job_token_scope_enabled).to be_truthy
    end
  end

  describe '#down' do
    it 'sets the job_token_scope_enabled default to false' do
      described_class.new.down

      settings = ci_cd_settings.create!(project_id: project.id)

      expect(settings.job_token_scope_enabled).to be_falsey
    end
  end
end
