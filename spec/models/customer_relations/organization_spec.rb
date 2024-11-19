# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Organization, type: :model, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }

  describe 'associations' do
    it { is_expected.to belong_to(:group).with_foreign_key('group_id') }
    it { is_expected.to have_many(:contacts) }
  end

  describe 'validations' do
    subject { build(:crm_organization) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:group_id]) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }

    context 'when root group' do
      subject { build(:crm_organization, group: group) }

      it { is_expected.to be_valid }

      context 'with group.source_group_id' do
        let(:crm_settings) { build(:crm_settings, source_group_id: group.id) }
        let(:root_group) { build(:group, crm_settings: crm_settings) }

        subject { build(:crm_organization, group: root_group) }

        it { is_expected.to be_invalid }
      end
    end

    context 'when subgroup' do
      subject { build(:crm_organization, group: build(:group, parent: group)) }

      it { is_expected.to be_invalid }

      context 'with group.crm_targets' do
        let(:target_group) { build(:group, crm_targets: [build(:crm_settings)], parent: group) }

        subject { build(:crm_organization, group: target_group) }

        it { is_expected.to be_valid }
      end
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
    let!(:crm_organiztion1) { create(:crm_organization, group: group, name: 'Test') }
    let!(:crm_organiztion2) { create(:crm_organization, group: create(:group), name: 'Test') }

    it 'strips name' do
      expect(described_class.find_by_name(group.id, 'TEST')).to eq([crm_organiztion1])
    end
  end

  describe '.search' do
    let_it_be(:crm_organization_a) do
      create(
        :crm_organization,
        group: group,
        name: "DEF",
        description: "ghi_st",
        state: "inactive"
      )
    end

    let_it_be(:crm_organization_b) do
      create(
        :crm_organization,
        group: group,
        name: "ABC_st",
        description: "JKL",
        state: "active"
      )
    end

    subject(:found_crm_organizations) { group.crm_organizations.search(search_term) }

    context 'when search term is empty' do
      let(:search_term) { "" }

      it 'returns all group crm_organizations' do
        expect(found_crm_organizations).to contain_exactly(crm_organization_a, crm_organization_b)
      end
    end

    context 'when search term is not empty' do
      context 'when searching for name' do
        let(:search_term) { "aBc" }

        it { is_expected.to contain_exactly(crm_organization_b) }
      end

      context 'when searching for description' do
        let(:search_term) { "ghI" }

        it { is_expected.to contain_exactly(crm_organization_a) }
      end

      context 'when searching for name and description' do
        let(:search_term) { "_st" }

        it { is_expected.to contain_exactly(crm_organization_a, crm_organization_b) }
      end
    end
  end

  describe '.search_by_state' do
    let_it_be(:crm_organization_a) { create(:crm_organization, group: group, state: "inactive") }
    let_it_be(:crm_organization_b) { create(:crm_organization, group: group, state: "active") }

    context 'when searching for crm_organizations state' do
      it 'returns only inactive crm_organizations' do
        expect(group.crm_organizations.search_by_state(:inactive)).to contain_exactly(crm_organization_a)
      end

      it 'returns only active crm_organizations' do
        expect(group.crm_organizations.search_by_state(:active)).to contain_exactly(crm_organization_b)
      end
    end
  end

  describe '.counts_by_state' do
    before do
      create_list(:crm_organization, 3, group: group)
      create_list(:crm_organization, 2, group: group, state: 'inactive')
    end

    it 'returns correct crm_organization counts' do
      counts = group.crm_organizations.counts_by_state

      expect(counts['active']).to be(3)
      expect(counts['inactive']).to be(2)
    end

    it 'returns 0 with no results' do
      counts = group.crm_organizations.where(id: non_existing_record_id).counts_by_state

      expect(counts['active']).to be(0)
      expect(counts['inactive']).to be(0)
    end
  end

  describe 'sorting' do
    let_it_be(:crm_organization_a) { create(:crm_organization, group: group, name: "c", description: "1") }
    let_it_be(:crm_organization_b) { create(:crm_organization, group: group, name: "a") }
    let_it_be(:crm_organization_c) { create(:crm_organization, group: group, name: "b", description: "2") }

    describe '.sort_by_name' do
      it 'sorts them by name in ascendent order' do
        expect(group.crm_organizations.sort_by_name).to eq([crm_organization_b, crm_organization_c, crm_organization_a])
      end
    end

    describe '.sort_by_field' do
      it 'sorts them by description in descending order' do
        expect(group.crm_organizations.sort_by_field('description', :desc))
          .to eq([crm_organization_c, crm_organization_a, crm_organization_b])
      end
    end
  end
end
