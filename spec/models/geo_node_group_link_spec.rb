require 'spec_helper'

describe GeoNodeGroupLink, models: true do
  describe 'relationships' do
    it { is_expected.to belong_to(:geo_node) }
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    let!(:geo_node_group_link) { create(:geo_node_group_link) }

    it { is_expected.to validate_presence_of(:geo_node_id) }
    it { is_expected.to validate_presence_of(:group_id) }
    it { is_expected.to validate_uniqueness_of(:group_id).scoped_to(:geo_node_id) }
  end
end
