require 'spec_helper'

describe Ci::Charts, lib: true do

  context "build_times" do
    before do
      @commit = FactoryGirl.create(:ci_commit)
      FactoryGirl.create(:ci_build, commit: @commit)
    end

    it 'should return build times in minutes' do
      chart = Ci::Charts::BuildTime.new(@commit.project)
      expect(chart.build_times).to eq([2])
    end

    it 'should handle nil build times' do
      create(:ci_commit, duration: nil, project: @commit.project)

      chart = Ci::Charts::BuildTime.new(@commit.project)
      expect(chart.build_times).to eq([2, 0])
    end
  end
end
