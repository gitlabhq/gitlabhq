require 'spec_helper'

describe "Charts" do

  context "build_times" do
    before do
      @project = FactoryGirl.create(:ci_project)
      @commit = FactoryGirl.create(:ci_commit, project: @project)
      FactoryGirl.create(:ci_build, commit: @commit)
    end

    it 'should return build times in minutes' do
      chart = Ci::Charts::BuildTime.new(@project)
      expect(chart.build_times).to eq([2])
    end
  end
end
