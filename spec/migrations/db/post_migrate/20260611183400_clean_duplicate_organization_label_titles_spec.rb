# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanDuplicateOrganizationLabelTitles, migration: :gitlab_main_org, feature_category: :team_planning do
  let(:organizations) { table(:organizations) }
  let(:labels) { table(:labels) }

  let!(:organization) { organizations.create!(name: 'Organization 1', path: 'organization-1') }
  let!(:other_organization) { organizations.create!(name: 'Organization 2', path: 'organization-2') }

  def create_label(title:, organization_id:)
    labels.create!(title: title, color: '#990000', template: true, organization_id: organization_id)
  end

  context 'when an organization label has a unique title' do
    let!(:label) { create_label(title: 'unique', organization_id: organization.id) }

    it 'does not modify the label' do
      expect { migrate! }.not_to change { label.reload.attributes }
    end
  end

  context 'when two organization labels share a title in the same organization' do
    let!(:label_one) { create_label(title: 'duped', organization_id: organization.id) }
    let!(:label_two) { create_label(title: 'duped', organization_id: organization.id) }

    it 'renames each duplicate with its own id', :aggregate_failures do
      migrate!

      expect(label_one.reload.title).to eq("duped [dup #{label_one.id}]")
      expect(label_two.reload.title).to eq("duped [dup #{label_two.id}]")
    end
  end

  context 'when labels share a title across different organizations' do
    let!(:label) { create_label(title: 'shared', organization_id: organization.id) }
    let!(:other_label) { create_label(title: 'shared', organization_id: other_organization.id) }

    it 'does not modify either label', :aggregate_failures do
      migrate!

      expect(label.reload.title).to eq('shared')
      expect(other_label.reload.title).to eq('shared')
    end
  end

  context 'when there are more duplicate labels than the batch size' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    let!(:duplicate_labels) do
      Array.new(3) { create_label(title: 'duped', organization_id: organization.id) }
    end

    it 'runs one UPDATE query per batch' do
      expect { migrate! }.to make_queries_matching(/UPDATE labels/, duplicate_labels.size)
    end

    it 'resolves duplicates into unique titles across batches', :aggregate_failures do
      migrate!

      titles = duplicate_labels.map { |label| label.reload.title }

      expect(titles.uniq.size).to eq(titles.size)
      expect(titles).to all(match(/\Aduped( \[dup \d+\])?\z/))
    end
  end
end
