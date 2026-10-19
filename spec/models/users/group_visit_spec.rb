# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::GroupVisit, feature_category: :navigation do
  let_it_be(:entity) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:base_time) { DateTime.now }

  it_behaves_like 'namespace visits model'

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:group_visit, entity_id: entity.id, user_id: user.id, visited_at: base_time) }
    let!(:parent) { entity }
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:group_visit, entity_id: entity.id, user_id: user.id, visited_at: base_time) }
    let!(:parent) { user }
  end

  describe '#frecent_groups' do
    let_it_be(:group1) { create(:group) }
    let_it_be(:group2) { create(:group) }

    before do
      [
        [group1.id, 1.day.ago],
        [group2.id, 2.days.ago]
      ].each do |id, datetime|
        described_class.create!(entity_id: id, user_id: user.id, visited_at: datetime)
      end
    end

    it "returns the associated frecently visited groups" do
      expect(described_class.frecent_groups(user_id: user.id)).to eq([
        group1,
        group2
      ])
    end

    context 'with an organization filter' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:visitor) { create(:user) }
      let_it_be(:group_in_organization) { create(:group, organization: organization) }
      let_it_be(:groups_in_other_organizations) { create_list(:group, described_class::MAX_FRECENT_ITEMS) }

      # A single shared timestamp keeps every visit in the same frecency week
      # bucket, so each group's score is simply its visit count.
      before do
        visited_at = 1.day.ago

        groups_in_other_organizations.each do |group|
          3.times do
            described_class.create!(entity_id: group.id, user_id: visitor.id, visited_at: visited_at)
          end
        end

        described_class.create!(entity_id: group_in_organization.id, user_id: visitor.id, visited_at: visited_at)
      end

      it 'returns groups in the organization that score below the unfiltered top results' do
        expect(described_class.frecent_groups(user_id: visitor.id))
          .to match_array(groups_in_other_organizations)

        expect(described_class.frecent_groups(user_id: visitor.id, organization_id: organization.id))
          .to contain_exactly(group_in_organization)
      end

      it 'returns an empty array when no visited group belongs to the organization' do
        expect(described_class.frecent_groups(user_id: visitor.id, organization_id: create(:organization).id))
          .to be_empty
      end
    end
  end
end
