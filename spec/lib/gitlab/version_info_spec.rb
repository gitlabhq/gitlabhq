require 'spec_helper'

describe 'Gitlab::VersionInfo', no_db: true do
  before do
    @unknown = Gitlab::VersionInfo.new
    @v0_0_1 = Gitlab::VersionInfo.new(0, 0, 1)
    @v0_1_0 = Gitlab::VersionInfo.new(0, 1, 0)
    @v1_0_0 = Gitlab::VersionInfo.new(1, 0, 0)
    @v1_0_1 = Gitlab::VersionInfo.new(1, 0, 1)
    @v1_1_0 = Gitlab::VersionInfo.new(1, 1, 0)
    @v2_0_0 = Gitlab::VersionInfo.new(2, 0, 0)
  end

  context '>' do
    it { @v2_0_0.should > @v1_1_0 }
    it { @v1_1_0.should > @v1_0_1 }
    it { @v1_0_1.should > @v1_0_0 }
    it { @v1_0_0.should > @v0_1_0 }
    it { @v0_1_0.should > @v0_0_1 }
  end

  context '>=' do
    it { @v2_0_0.should >= Gitlab::VersionInfo.new(2, 0, 0) }
    it { @v2_0_0.should >= @v1_1_0 }
  end

  context '<' do
    it { @v0_0_1.should < @v0_1_0 }
    it { @v0_1_0.should < @v1_0_0 }
    it { @v1_0_0.should < @v1_0_1 }
    it { @v1_0_1.should < @v1_1_0 }
    it { @v1_1_0.should < @v2_0_0 }
  end

  context '<=' do
    it { @v0_0_1.should <= Gitlab::VersionInfo.new(0, 0, 1) }
    it { @v0_0_1.should <= @v0_1_0 }
  end

  context '==' do
    it { @v0_0_1.should == Gitlab::VersionInfo.new(0, 0, 1) }
    it { @v0_1_0.should == Gitlab::VersionInfo.new(0, 1, 0) }
    it { @v1_0_0.should == Gitlab::VersionInfo.new(1, 0, 0) }
  end

  context '!=' do
    it { @v0_0_1.should_not == @v0_1_0 }
  end

  context 'unknown' do
    it { @unknown.should_not be @v0_0_1 }
    it { @unknown.should_not be Gitlab::VersionInfo.new }
    it { expect{@unknown > @v0_0_1}.to raise_error(ArgumentError) }
    it { expect{@unknown < @v0_0_1}.to raise_error(ArgumentError) }
  end

  context 'parse' do
    it { Gitlab::VersionInfo.parse("1.0.0").should == @v1_0_0 }
    it { Gitlab::VersionInfo.parse("1.0.0.1").should == @v1_0_0 }
    it { Gitlab::VersionInfo.parse("git 1.0.0b1").should == @v1_0_0 }
    it { Gitlab::VersionInfo.parse("git 1.0b1").should_not be_valid }
  end

  context 'to_s' do
    it { @v1_0_0.to_s.should == "1.0.0" }
    it { @unknown.to_s.should == "Unknown" }
  end
end

