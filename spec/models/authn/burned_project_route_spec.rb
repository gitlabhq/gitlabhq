# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::BurnedProjectRoute, feature_category: :continuous_integration do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).class_name('Organizations::Organization') }
  end

  describe 'validations' do
    subject(:burn) { build(:burned_project_route) }

    it { is_expected.to validate_presence_of(:organization_id) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:burned_at) }

    it 'accepts and persists a path longer than 255 characters' do
      # routes.path is unbounded and can exceed 255 chars via descendant
      # rewrites (parent-group rename / mark-for-deletion). Neither the model
      # nor the table must re-introduce a 255-char ceiling that would drop
      # burn protection. Uses create to exercise the DB constraint removal.
      expect(create(:burned_project_route, path: 'a' * 256)).to be_persisted
    end
  end

  describe 'scopes' do
    describe '.for_path' do
      let!(:row) { create(:burned_project_route, path: 'group/widgets') }

      it 'matches the path case-insensitively' do
        expect(described_class.for_path('GROUP/WIDGETS')).to contain_exactly(row)
      end

      it 'does not match unrelated paths' do
        expect(described_class.for_path('group/other')).to be_empty
      end
    end
  end

  describe '.blocked_for?' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:other_organization) { create(:organization) }
    let(:path) { 'group/widgets' }
    let(:burned_project_id) { non_existing_record_id }
    let(:other_project_id)  { non_existing_record_id - 1 }

    context 'when no tombstone exists for the path' do
      it 'returns false' do
        expect(
          described_class.blocked_for?(organization_id: organization.id, path: path,
            except_project_id: other_project_id)
        ).to be(false)
      end
    end

    context 'when a burn record exists for a different project in the same organization' do
      before do
        create(:burned_project_route, organization: organization, path: path, project_id: burned_project_id)
      end

      it 'returns true' do
        expect(
          described_class.blocked_for?(organization_id: organization.id, path: path,
            except_project_id: other_project_id)
        ).to be(true)
      end

      it 'returns false when the requesting project matches the original owner' do
        expect(
          described_class.blocked_for?(organization_id: organization.id, path: path,
            except_project_id: burned_project_id)
        ).to be(false)
      end

      it 'returns true when no project_id is provided (no exemption)' do
        expect(
          described_class.blocked_for?(organization_id: organization.id, path: path, except_project_id: nil)
        ).to be(true)
      end

      it 'returns false when the burn lives in a different organization' do
        expect(
          described_class.blocked_for?(organization_id: other_organization.id, path: path,
            except_project_id: other_project_id)
        ).to be(false)
      end
    end

    it 'matches the path case-insensitively' do
      create(:burned_project_route, organization: organization, path: 'Group/Widgets', project_id: burned_project_id)

      expect(
        described_class.blocked_for?(organization_id: organization.id, path: 'group/widgets',
          except_project_id: other_project_id)
      ).to be(true)
    end

    it 'returns false when organization_id is blank' do
      create(:burned_project_route, organization: organization, path: path, project_id: burned_project_id)

      expect(described_class.blocked_for?(organization_id: nil, path: path,
        except_project_id: other_project_id)).to be(false)
    end
  end

  describe '.burn!' do
    let_it_be(:organization) { create(:organization) }
    let(:path) { 'group/widgets' }
    let(:new_project_id)      { non_existing_record_id }
    let(:existing_project_id) { non_existing_record_id - 1 }

    context 'when no tombstone exists' do
      it 'inserts a new tombstone with burned_at set' do
        expect { described_class.burn!(organization_id: organization.id, path: path, project_id: new_project_id) }
          .to change { described_class.count }.by(1)

        row = described_class.for_path(path).order(:id).first
        expect(row.organization_id).to eq(organization.id)
        expect(row.project_id).to eq(new_project_id)
        expect(row.burned_at).to be_within(5.seconds).of(Time.current)
      end
    end

    context 'when a tombstone already exists for the same organization and path' do
      let!(:existing) do
        create(:burned_project_route,
          organization: organization, path: path, project_id: existing_project_id, burned_at: 1.day.ago)
      end

      it 'does not modify the existing tombstone on duplicate burn' do
        existing.reload
        original_burned_at = existing.burned_at

        expect { described_class.burn!(organization_id: organization.id, path: path, project_id: new_project_id) }
          .not_to change { described_class.count }

        existing.reload
        expect(existing.project_id).to eq(existing_project_id)
        expect(existing.burned_at).to eq(original_burned_at)
      end
    end

    context 'when the same path is burned in a different organization' do
      let_it_be(:other_organization) { create(:organization) }

      before do
        create(:burned_project_route,
          organization: other_organization, path: path, project_id: existing_project_id)
      end

      it 'inserts a separate tombstone scoped to the new organization' do
        expect { described_class.burn!(organization_id: organization.id, path: path, project_id: new_project_id) }
          .to change { described_class.count }.by(1)

        rows = described_class.for_path(path)
        expect(rows.pluck(:organization_id)).to contain_exactly(organization.id, other_organization.id)
      end
    end
  end

  describe '.bulk_burn!' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:other_organization) { create(:organization) }
    let_it_be(:project_a) { create(:project, organization: organization) }
    let_it_be(:project_b) { create(:project, organization: organization) }
    let_it_be(:project_c) { create(:project, organization: other_organization) }

    it 'is a no-op when rows is blank' do
      expect { described_class.bulk_burn!([]) }.not_to change { described_class.count }
      expect { described_class.bulk_burn!(nil) }.not_to change { described_class.count }
    end

    it 'inserts one tombstone per row with the project organization_id' do
      rows = [
        { path: 'group-a/widgets', project_id: project_a.id },
        { path: 'group-a/gadgets', project_id: project_b.id },
        { path: 'group-b/widgets', project_id: project_c.id }
      ]

      expect { described_class.bulk_burn!(rows) }.to change { described_class.count }.by(3)

      expect(described_class.for_path('group-a/widgets').pick(:organization_id)).to eq(organization.id)
      expect(described_class.for_path('group-a/gadgets').pick(:organization_id)).to eq(organization.id)
      expect(described_class.for_path('group-b/widgets').pick(:organization_id)).to eq(other_organization.id)
    end

    it 'does not modify the existing tombstone when a duplicate path is bulk-burned' do
      existing = create(:burned_project_route,
        organization: organization, path: 'group-a/widgets', project_id: project_a.id, burned_at: 1.day.ago)
      existing.reload
      original_burned_at = existing.burned_at

      expect do
        described_class.bulk_burn!([{ path: 'group-a/widgets', project_id: project_b.id }])
      end.not_to change { described_class.count }

      row = described_class.for_path('group-a/widgets').order(:id).first
      expect(row.project_id).to eq(project_a.id)
      expect(row.burned_at).to eq(original_burned_at)
    end

    it 'skips rows whose project no longer exists' do
      rows = [
        { path: 'group-a/widgets', project_id: project_a.id },
        { path: 'gone/orphan',     project_id: non_existing_record_id }
      ]

      expect { described_class.bulk_burn!(rows) }.to change { described_class.count }.by(1)
      expect(described_class.for_path('gone/orphan')).to be_empty
    end

    it 'skips rows with blank path' do
      rows = [
        { path: 'group-a/widgets', project_id: project_a.id },
        { path: '',                project_id: project_b.id },
        { path: nil,               project_id: project_b.id }
      ]

      expect { described_class.bulk_burn!(rows) }.to change { described_class.count }.by(1)
    end
  end
end
