# == Schema Information
#
# Table name: label_links
#
#  id          :integer          not null, primary key
#  label_id    :integer
#  target_id   :integer
#  target_type :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe LabelLink, models: true do
  let(:label) { create(:label_link) }
  it { expect(label).to be_valid }

  it { is_expected.to belong_to(:label) }
  it { is_expected.to belong_to(:target) }
end
