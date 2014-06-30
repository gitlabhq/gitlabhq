# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#  recipients  :text
#  api_key     :string(255)
#

require 'spec_helper'

describe Service do

  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe "Mass assignment" do
  end

  describe "Test Button" do
    before do
      @service = Service.new
    end

    describe "Testable" do
      let (:project) { create :project }

      before do
        @service.stub(
          project: project
        )
        @testable = @service.can_test?
      end

      describe :can_test do
        it { @testable.should == true }
      end
    end

    describe "With commits" do
      let (:project) { create :project }

      before do
        @service.stub(
          project: project
        )
        @testable = @service.can_test?
      end

      describe :can_test do
        it { @testable.should == true }
      end
    end
  end
end
