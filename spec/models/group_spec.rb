# == Schema Information
#
# Table name: groups
#
#  id         :integer         not null, primary key
#  name       :string(255)     not null
#  code       :string(255)     not null
#  owner_id   :integer         not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

require 'spec_helper'

describe Group do
  let!(:group) { create(:group) }

  it { should have_many :projects }
  it { should validate_presence_of :name }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of :code }
  it { should validate_uniqueness_of(:code) }
  it { should validate_presence_of :owner }
end
