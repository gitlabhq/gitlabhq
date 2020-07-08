# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::SemVer, type: :model do
  shared_examples '#parse with a valid semver' do |str, major, minor, patch, prerelease, build|
    context "with #{str}" do
      it "returns #{described_class.new(major, minor, patch, prerelease, build, prefixed: true)} with prefix" do
        expected = described_class.new(major, minor, patch, prerelease, build, prefixed: true)
        expect(described_class.parse('v' + str, prefixed: true)).to eq(expected)
      end

      it "returns #{described_class.new(major, minor, patch, prerelease, build)} without prefix" do
        expected = described_class.new(major, minor, patch, prerelease, build)
        expect(described_class.parse(str)).to eq(expected)
      end
    end
  end

  shared_examples '#parse with an invalid semver' do |str|
    context "with #{str}" do
      it 'returns nil with prefix' do
        expect(described_class.parse('v' + str, prefixed: true)).to be_nil
      end

      it 'returns nil without prefix' do
        expect(described_class.parse(str)).to be_nil
      end
    end
  end

  describe '#parse' do
    it_behaves_like '#parse with a valid semver', '1.0.0', 1, 0, 0, nil, nil
    it_behaves_like '#parse with a valid semver', '1.0.0-pre', 1, 0, 0, 'pre', nil
    it_behaves_like '#parse with a valid semver', '1.0.0+build', 1, 0, 0, nil, 'build'
    it_behaves_like '#parse with a valid semver', '1.0.0-pre+build', 1, 0, 0, 'pre', 'build'
    it_behaves_like '#parse with an invalid semver', '01.0.0'
    it_behaves_like '#parse with an invalid semver', '0.01.0'
    it_behaves_like '#parse with an invalid semver', '0.0.01'
    it_behaves_like '#parse with an invalid semver', '1.0.0asdf'
  end
end
