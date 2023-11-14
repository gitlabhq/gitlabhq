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
  end
end
