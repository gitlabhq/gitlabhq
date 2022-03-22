# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Organization, type: :model do
  let_it_be(:group) { create(:group) }

  describe 'associations' do
    it { is_expected.to belong_to(:group).with_foreign_key('group_id') }
  end

  describe 'validations' do
    subject { build(:organization) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:group_id]) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  end

  describe '#root_group' do
    context 'when root group' do
      subject { build(:organization, group: group) }

      it { is_expected.to be_valid }
    end

    context 'when subgroup' do
      subject { build(:organization, group: create(:group, parent: group)) }

      it { is_expected.to be_invalid }
    end
  end

  describe '#name' do
    it 'strips name' do
      organization = described_class.new(name: '   GitLab   ')
      organization.valid?

      expect(organization.name).to eq('GitLab')
    end
  end

  describe '#find_by_name' do
    let!(:organiztion1) { create(:organization, group: group, name: 'Test') }
    let!(:organiztion2) { create(:organization, group: create(:group), name: 'Test') }

    it 'strips name' do
      expect(described_class.find_by_name(group.id, 'TEST')).to eq([organiztion1])
    end
  end

  describe '#self.move_to_root_group' do
    let!(:old_root_group) { create(:group) }
    let!(:organizations) { create_list(:organization, 4, group: old_root_group) }
    let!(:new_root_group) { create(:group) }
    let!(:contact1) { create(:contact, group: new_root_group, organization: organizations[0]) }
    let!(:contact2) { create(:contact, group: new_root_group, organization: organizations[1]) }

    let!(:dupe_organization1) { create(:organization, group: new_root_group, name: organizations[1].name) }
    let!(:dupe_organization2) { create(:organization, group: new_root_group, name: organizations[3].name.upcase) }

    before do
      old_root_group.update!(parent: new_root_group)
      CustomerRelations::Organization.move_to_root_group(old_root_group)
    end

    it 'moves organizations with unique names and deletes the rest' do
      expect(organizations[0].reload.group_id).to eq(new_root_group.id)
      expect(organizations[2].reload.group_id).to eq(new_root_group.id)
      expect { organizations[1].reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { organizations[3].reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'updates contact.organization_id for dupes and leaves the rest untouched' do
      expect(contact1.reload.organization_id).to eq(organizations[0].id)
      expect(contact2.reload.organization_id).to eq(dupe_organization1.id)
    end
  end
end
