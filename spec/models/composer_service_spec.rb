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

      it { should validate_presence_of :package_parser }
      it { should validate_presence_of :package_type }
    end
  end

  describe 'Execute' do
    let(:package_parser) { 0 }
    let(:package_type) { 'library' }
    let(:package_homepage) { '' }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
  end

end