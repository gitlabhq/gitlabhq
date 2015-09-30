# == Schema Information
#
# Table name: runners
#
#  id           :integer          not null, primary key
#  token        :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  description  :string(255)
#  contacted_at :datetime
#  active       :boolean          default(TRUE), not null
#  is_shared    :boolean          default(FALSE)
#  name         :string(255)
#  version      :string(255)
#  revision     :string(255)
#  platform     :string(255)
#  architecture :string(255)
#

require 'spec_helper'

describe Ci::Runner do
  describe '#display_name' do
    it 'should return the description if it has a value' do
      runner = FactoryGirl.build(:ci_runner, description: 'Linux/Ruby-1.9.3-p448')
      expect(runner.display_name).to eq 'Linux/Ruby-1.9.3-p448'
    end

    it 'should return the token if it does not have a description' do
      runner = FactoryGirl.create(:ci_runner)
      expect(runner.display_name).to eq runner.description
    end

    it 'should return the token if the description is an empty string' do
      runner = FactoryGirl.build(:ci_runner, description: '')
      expect(runner.display_name).to eq runner.token
    end
  end

  describe :assign_to do
    let!(:project) { FactoryGirl.create :ci_project }
    let!(:shared_runner) { FactoryGirl.create(:ci_shared_runner) }

    before { shared_runner.assign_to(project) }

    it { expect(shared_runner).to be_specific }
    it { expect(shared_runner.projects).to eq([project]) }
    it { expect(shared_runner.only_for?(project)).to be_truthy }
  end

  describe "belongs_to_one_project?" do
    it "returns false if there are two projects runner assigned to" do
      runner = FactoryGirl.create(:ci_specific_runner)
      project = FactoryGirl.create(:ci_project)
      project1 = FactoryGirl.create(:ci_project)
      project.runners << runner
      project1.runners << runner

      expect(runner.belongs_to_one_project?).to be_falsey
    end

    it "returns true" do
      runner = FactoryGirl.create(:ci_specific_runner)
      project = FactoryGirl.create(:ci_project)
      project.runners << runner

      expect(runner.belongs_to_one_project?).to be_truthy
    end
  end
end
