# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#  api_key     :string(255)
#

require 'spec_helper'

describe Service do

  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
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

  describe :doc do
    before do
      @service = Service.new
      @service.stub(:to_param).and_return("example")
    end

    context "without documentation file" do
      before do
        Gitlab::ServiceDoc.instance_variable_set(:@docs, {"another_service" => "Some service documentation"})
      end

      it { @service.doc.should be_nil }
    end

    context "with documentation file provided" do
      before do
        Gitlab::ServiceDoc.instance_variable_set(:@docs, {@service.to_param => "Some service documentation"})
      end

      it { @service.doc.should == "Some service documentation" }
    end

    context "when something bad happens" do
      before do
        Gitlab::ServiceDoc.stub(:get).and_raise("something bad")
      end

      it { expect { @service.doc }.to_not raise_error }
      it { @service.doc.should be_nil }
    end

  end
end
