require 'spec_helper'

describe Gitlab::GitStats do

  describe "#parsed_log" do
    let(:stats) { Gitlab::GitStats.new(nil, nil) }
    before(:each) do
      stats.stub(:log).and_return("anything")
    end

    context "LogParser#parse_log returns 'test'" do
      it "returns 'test'" do
        LogParser.stub(:parse_log).and_return("test")
        stats.parsed_log.should eq("test")
      end
    end
  end

  describe "#log" do
    let(:repo) { Repository.new(nil, nil) }
    let(:gs) { Gitlab::GitStats.new(repo.raw, repo.root_ref) }
    
    before(:each) do
      repo.stub(:raw).and_return(nil)
      repo.stub(:root_ref).and_return(nil)
      repo.raw.stub(:git)
    end

    context "repo.git.run returns 'test'" do
      it "returns 'test'" do
        repo.raw.git.stub(:run).and_return("test")
        gs.log.should eq("test")
      end
    end
  end
end