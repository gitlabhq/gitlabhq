# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateCodeReviewFoundationalFlowDescription,
  migration: :gitlab_main,
  feature_category: :duo_agent_platform do
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:organizations) { table(:organizations) }
  let(:old_description) { described_class::OLD_DESCRIPTION }
  let(:new_description) { described_class::NEW_DESCRIPTION }
  let!(:organization) { organizations.create!(name: 'Organization 1', path: 'organization-1') }
  let!(:code_review_item) do
    create_item(reference: 'code_review/v1', description: old_description)
  end

  def create_item(reference:, description:)
    ai_catalog_items.create!(
      name: 'Test',
      description: description,
      public: true,
      organization_id: organization.id,
      item_type: 2,
      foundational_flow_reference: reference
    )
  end

  it 'updates the Code Review item description' do
    expect { migrate! }
      .to change { code_review_item.reload.description }
      .from(old_description).to(new_description)
  end

  context 'when the description has already been updated' do
    let!(:code_review_item) do
      create_item(reference: 'code_review/v1', description: new_description)
    end

    it 'does not modify the row' do
      expect { migrate! }.not_to change { code_review_item.reload.description }
    end
  end

  context 'when the description has been customized' do
    let(:custom_description) { 'A custom description set by an admin.' }

    let!(:code_review_item) do
      create_item(reference: 'code_review/v1', description: custom_description)
    end

    it 'does not clobber the customization' do
      expect { migrate! }.not_to change { code_review_item.reload.description }
    end
  end

  context 'with other foundational flows that share the wording' do
    let!(:other_flow) do
      create_item(reference: 'developer/v1', description: old_description)
    end

    it 'does not touch other foundational flow rows' do
      expect { migrate! }.not_to change { other_flow.reload.description }
    end
  end

  describe '#down' do
    before do
      migrate!
    end

    it 'reverts to the previous description' do
      expect { schema_migrate_down! }
        .to change { code_review_item.reload.description }
        .from(new_description).to(old_description)
    end
  end
end
