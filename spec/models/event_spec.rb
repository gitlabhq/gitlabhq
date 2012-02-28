# == Schema Information
#
# Table name: events
#
#  id          :integer         not null, primary key
#  target_type :string(255)
#  target_id   :integer
#  title       :string(255)
#  data        :text
#  project_id  :integer
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#  action      :integer
#

require 'spec_helper'

describe Event do
  describe "Associations" do
    it { should belong_to(:project) }
  end

  describe "Creation" do
    before do 
      @event = Factory :event
    end

    it "should create a valid event" do 
      @event.should be_valid
    end
  end
end
