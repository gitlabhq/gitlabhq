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

  describe '<=>' do
    it 'returns -1 when left version is lower' do
      expect(described_class.new(1, 0, 0) <=> described_class.new(2, 0, 0)).to eq(-1)
    end

    it 'returns 1 when left version is higher' do
      expect(described_class.new(2, 0, 0) <=> described_class.new(1, 0, 0)).to eq(1)
    end

    it 'returns 0 when versions are equal' do
      expect(described_class.new(1, 2, 3) <=> described_class.new(1, 2, 3)).to eq(0)
    end

    it 'compares minor and patch versions' do
      expect(described_class.new(1, 2, 0) <=> described_class.new(1, 3, 0)).to eq(-1)
      expect(described_class.new(1, 2, 3) <=> described_class.new(1, 2, 4)).to eq(-1)
    end

    it 'ranks release higher than prerelease for same version' do
      expect(described_class.new(1, 0, 0) <=> described_class.new(1, 0, 0, 'alpha')).to eq(1)
      expect(described_class.new(1, 0, 0, 'alpha') <=> described_class.new(1, 0, 0)).to eq(-1)
    end

    it 'compares numeric prerelease identifiers numerically' do
      expect(described_class.new(1, 0, 0, '2') <=> described_class.new(1, 0, 0, '11')).to eq(-1)
    end

    it 'ranks numeric identifiers lower than non-numeric' do
      expect(described_class.new(1, 0, 0, '1') <=> described_class.new(1, 0, 0, 'alpha')).to eq(-1)
      expect(described_class.new(1, 0, 0, 'alpha') <=> described_class.new(1, 0, 0, '1')).to eq(1)
    end

    it 'compares dot-separated prerelease identifiers' do
      expect(described_class.new(1, 0, 0, 'alpha.1') <=> described_class.new(1, 0, 0, 'alpha.beta')).to eq(-1)
    end

    it 'ranks larger set of prerelease identifiers higher' do
      expect(described_class.new(1, 0, 0, 'alpha') <=> described_class.new(1, 0, 0, 'alpha.1')).to eq(-1)
      expect(described_class.new(1, 0, 0, 'alpha.1') <=> described_class.new(1, 0, 0, 'alpha')).to eq(1)
    end

    it 'follows semver 2.0.0 precedence order' do
      versions = %w[
        1.0.0-alpha
        1.0.0-alpha.1
        1.0.0-alpha.beta
        1.0.0-beta
        1.0.0-beta.2
        1.0.0-beta.11
        1.0.0-rc.1
      ].map { |v| described_class.parse(v) }

      versions.each_cons(2) do |lower, higher|
        expect(lower <=> higher).to eq(-1), "expected #{lower} < #{higher}"
      end
    end

    it 'returns nil for non-SemVer comparisons' do
      expect(described_class.new(1, 0, 0) <=> 'not a semver').to be_nil
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
