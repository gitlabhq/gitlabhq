# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe 'Gitlab::VersionInfo' do
  before do
    @unknown = Gitlab::VersionInfo.new
    @v0_0_1 = Gitlab::VersionInfo.new(0, 0, 1)
    @v0_1_0 = Gitlab::VersionInfo.new(0, 1, 0)
    @v1_0_0 = Gitlab::VersionInfo.new(1, 0, 0)
    @v1_0_1 = Gitlab::VersionInfo.new(1, 0, 1)
    @v1_1_0 = Gitlab::VersionInfo.new(1, 1, 0)
    @v2_0_0 = Gitlab::VersionInfo.new(2, 0, 0)
  end

  describe '>' do
    it { expect(@v2_0_0).to be > @v1_1_0 }
    it { expect(@v1_1_0).to be > @v1_0_1 }
    it { expect(@v1_0_1).to be > @v1_0_0 }
    it { expect(@v1_0_0).to be > @v0_1_0 }
    it { expect(@v0_1_0).to be > @v0_0_1 }
  end

  describe '>=' do
    it { expect(@v2_0_0).to be >= Gitlab::VersionInfo.new(2, 0, 0) }
    it { expect(@v2_0_0).to be >= @v1_1_0 }
  end

  describe '<' do
    it { expect(@v0_0_1).to be < @v0_1_0 }
    it { expect(@v0_1_0).to be < @v1_0_0 }
    it { expect(@v1_0_0).to be < @v1_0_1 }
    it { expect(@v1_0_1).to be < @v1_1_0 }
    it { expect(@v1_1_0).to be < @v2_0_0 }
  end

  describe '<=' do
    it { expect(@v0_0_1).to be <= Gitlab::VersionInfo.new(0, 0, 1) }
    it { expect(@v0_0_1).to be <= @v0_1_0 }
  end

  describe '==' do
    it { expect(@v0_0_1).to eq(Gitlab::VersionInfo.new(0, 0, 1)) }
    it { expect(@v0_1_0).to eq(Gitlab::VersionInfo.new(0, 1, 0)) }
    it { expect(@v1_0_0).to eq(Gitlab::VersionInfo.new(1, 0, 0)) }
  end

  describe '!=' do
    it { expect(@v0_0_1).not_to eq(@v0_1_0) }
  end

  describe '.unknown' do
    it { expect(@unknown).not_to be @v0_0_1 }
    it { expect(@unknown).not_to be Gitlab::VersionInfo.new }
    it { expect {@unknown > @v0_0_1}.to raise_error(ArgumentError) }
    it { expect {@unknown < @v0_0_1}.to raise_error(ArgumentError) }
  end

  describe '.parse' do
    it { expect(Gitlab::VersionInfo.parse("1.0.0")).to eq(@v1_0_0) }
    it { expect(Gitlab::VersionInfo.parse("1.0.0.1")).to eq(@v1_0_0) }
    it { expect(Gitlab::VersionInfo.parse("1.0.0-ee")).to eq(@v1_0_0) }
    it { expect(Gitlab::VersionInfo.parse("1.0.0-rc1")).to eq(@v1_0_0) }
    it { expect(Gitlab::VersionInfo.parse("1.0.0-rc1-ee")).to eq(@v1_0_0) }
    it { expect(Gitlab::VersionInfo.parse("git 1.0.0b1")).to eq(@v1_0_0) }
    it { expect(Gitlab::VersionInfo.parse("git 1.0b1")).not_to be_valid }
  end

  describe '.to_s' do
    it { expect(@v1_0_0.to_s).to eq("1.0.0") }
    it { expect(@unknown.to_s).to eq("Unknown") }
  end

  describe '.hash' do
    it { expect(Gitlab::VersionInfo.parse("1.0.0").hash).to eq(@v1_0_0.hash) }
    it { expect(Gitlab::VersionInfo.parse("1.0.0.1").hash).to eq(@v1_0_0.hash) }
    it { expect(Gitlab::VersionInfo.parse("1.0.1b1").hash).to eq(@v1_0_1.hash) }
  end

  describe '.eql?' do
    it { expect(Gitlab::VersionInfo.parse("1.0.0").eql?(@v1_0_0)).to be_truthy }
    it { expect(Gitlab::VersionInfo.parse("1.0.0.1").eql?(@v1_0_0)).to be_truthy }
    it { expect(@v1_0_1.eql?(@v1_0_0)).to be_falsey }
    it { expect(@v1_1_0.eql?(@v1_0_0)).to be_falsey }
    it { expect(@v1_0_0.eql?(@v1_0_0)).to be_truthy }
    it { expect([@v1_0_0, @v1_1_0, @v1_0_0].uniq).to eq [@v1_0_0, @v1_1_0] }
  end

  describe '.same_minor_version?' do
    it { expect(@v0_1_0.same_minor_version?(@v0_0_1)).to be_falsey }
    it { expect(@v1_0_1.same_minor_version?(@v1_0_0)).to be_truthy }
    it { expect(@v1_0_0.same_minor_version?(@v1_0_1)).to be_truthy }
    it { expect(@v1_1_0.same_minor_version?(@v1_0_0)).to be_falsey }
    it { expect(@v2_0_0.same_minor_version?(@v1_0_0)).to be_falsey }
  end

  describe '.without_patch' do
    it { expect(@v0_1_0.without_patch).to eq(@v0_1_0) }
    it { expect(@v1_0_0.without_patch).to eq(@v1_0_0) }
    it { expect(@v1_0_1.without_patch).to eq(@v1_0_0) }
  end
end
