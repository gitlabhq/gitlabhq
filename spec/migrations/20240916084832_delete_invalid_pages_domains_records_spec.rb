# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteInvalidPagesDomainsRecords, feature_category: :pages do
  let!(:pages_domains) { table(:pages_domains) }

  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:user) { table(:users).create!(email: 'test@example.com', projects_limit: 10) }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  describe '#up' do
    before do
      pages_domains.create!(project_id: project.id, domain: 'example.com', verification_code: 'example')
      pages_domains.create!(project_id: nil, domain: 'example2.com', verification_code: 'example2')
      pages_domains.create!(project_id: nil, domain: 'example3.com', verification_code: 'example3')

      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'deletes records without a project_id' do
      migrate!

      expect(pages_domains.count).to eq(1)
      expect(pages_domains.first).to have_attributes(project_id: project.id, domain: 'example.com')
    end
  end
end
