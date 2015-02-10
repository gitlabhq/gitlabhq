# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require 'spec_helper'

describe ComposerService do

  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe 'Validations' do
    context 'active' do
      before do
        subject.active = true
      end

      it { should validate_presence_of :package_mode }
      it { should validate_presence_of :package_type }
    end
  end

  describe "Test Button not available" do
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
        it { @testable.should == false }
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
        it { @testable.should == false }
      end
    end
  end

end
