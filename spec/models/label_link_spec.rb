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

describe LabelLink do
  let(:label) { create(:label_link) }
  it { label.should be_valid }

  it { should belong_to(:label) }
  it { should belong_to(:target) }
end
