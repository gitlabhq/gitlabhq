# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserAgentDetailsOrganizationId, feature_category: :instance_resiliency do
  let(:connection) { ApplicationRecord.connection }

  let(:issues) { table(:issues) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:user_agent_details) { table(:user_agent_details) { |t| t.belongs_to :subject, polymorphic: true } }

  let!(:default_organization) { organizations.create!(id: 1, name: 'default', path: 'default') }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace1) { namespaces.create!(name: 'namespace 1', path: 'namespace1', organization_id: organization.id) }
  let(:project1) do
    projects.create!(namespace_id: namespace1.id, project_namespace_id: namespace1.id, organization_id: organization.id)
  end

  let(:issue1) do
    issues.create!(namespace_id: namespace1.id, project_id: project1.id, created_at: 5.days.ago, closed_at: 3.days.ago,
      work_item_type_id: work_item_type_id)
  end

  let(:issue2) do
    issues.create!(namespace_id: namespace1.id, project_id: project1.id, created_at: 7.days.ago, closed_at: 2.days.ago,
      work_item_type_id: work_item_type_id)
  end

  let(:work_item_type_id) { table(:work_item_types).where(base_type: 1).first.id }

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: user_agent_details.minimum(:id),
        end_id: user_agent_details.maximum(:id),
        batch_table: :user_agent_details,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      )
    end

    before do
      create_user_agent_detail!(organization: organization, target: issue1)
      create_user_agent_detail!(organization: organization, target: issue2)
      create_user_agent_detail!(organization: nil, target: issue1)
      create_user_agent_detail!(organization: nil, target: issue2)
    end

    it 'updates records without an organization' do
      expect { migration.perform }.to change { user_agent_details.where(organization_id: nil).count }.from(2).to(0)
    end
  end

  def create_user_agent_detail!(target:, organization: nil)
    user_agent_details.create!(
      organization_id: organization&.id,
      ip_address: '127.0.0.1',
      user_agent: 'Mozilla/5.0 (X11; Linux i686; rv:136.0) Gecko/20100101 Firefox/136.0',
      subject_id: target&.id,
      subject_type: target.class.name
    )
  end
end
