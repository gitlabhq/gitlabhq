# == Schema Information
#
# Table name: namespaces
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  path       :string(255)      not null
#  owner_id   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string(255)
#

require 'spec_helper'

describe Namespace do
  let!(:namespace) { create(:namespace) }

  it { should have_many :projects }
  it { should validate_presence_of :name }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of :path }
  it { should validate_uniqueness_of(:path) }
  it { should validate_presence_of :owner }

  describe "Mass assignment" do
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:path) }
  end

  describe "Respond to" do
    it { should respond_to(:human_name) }
    it { should respond_to(:to_param) }
  end
end
