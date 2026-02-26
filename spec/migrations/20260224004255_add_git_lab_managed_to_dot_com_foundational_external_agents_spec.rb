# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddGitLabManagedToDotComFoundationalExternalAgents, migration: :gitlab_main, feature_category: :workflow_catalog do
  let(:organizations) { table(:organizations) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }

  let!(:organization) { organizations.create!(name: 'Organization', path: 'organization') }

  let!(:target_items) do
    Array.new(3) do |i|
      ai_catalog_items.create!(
        name: "External Agent #{i}",
        description: 'A foundational external agent',
        item_type: 3,
        organization_id: organization.id,
        verification_level: described_class::UNVERIFIED
      )
    end
  end

  let!(:other_item) do
    ai_catalog_items.create!(
      name: 'Other Item',
      description: 'An unrelated item',
      item_type: 3,
      organization_id: organization.id,
      verification_level: described_class::UNVERIFIED
    )
  end

  before do
    stub_const("#{described_class}::ITEM_IDS", target_items.map(&:id))
  end

  context 'on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    describe '#up' do
      it 'updates verification_level to gitlab_maintained for target items' do
        migrate!

        target_items.each do |item|
          expect(item.reload.verification_level).to eq(described_class::GITLAB_MAINTAINED)
        end
      end

      it 'does not update other items' do
        migrate!

        expect(other_item.reload.verification_level).to eq(described_class::UNVERIFIED)
      end
    end

    describe '#down' do
      it 'reverts verification_level to unverified for target items' do
        migrate!
        schema_migrate_down!

        target_items.each do |item|
          expect(item.reload.verification_level).to eq(described_class::UNVERIFIED)
        end
      end

      it 'does not update other items' do
        migrate!
        schema_migrate_down!

        expect(other_item.reload.verification_level).to eq(described_class::UNVERIFIED)
      end
    end
  end

  context 'on self-managed' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    describe '#up' do
      it 'does not update any items' do
        migrate!

        target_items.each do |item|
          expect(item.reload.verification_level).to eq(described_class::UNVERIFIED)
        end
      end
    end
  end
end
