# == Schema Information
#
# Table name: keys
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#  key         :text
#  title       :string(255)
#  type        :string(255)
#  fingerprint :string(255)
#  public      :boolean          default(FALSE), not null
#

require 'spec_helper'

describe GeoNodeKey, models: true do
  let(:geo_node) { create(:geo_node) }
  let(:geo_node_key) { create(:geo_node_key, geo_nodes: [geo_node]) }

  describe 'Associations' do
    it { is_expected.to have_one(:geo_node) }
  end
end
