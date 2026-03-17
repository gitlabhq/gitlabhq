# frozen_string_literal: true

require_relative '../../../scripts/setup/gitaly_version_checker'

RSpec.describe GitalyVersionChecker, feature_category: :gitaly do
  let(:checker) { described_class.new }

  describe '#parse_gitlab_version' do
    context 'with valid VERSION file' do
      it 'parses a simple semantic version' do
        version = checker.parse_gitlab_version('17.5.2')
        expect(version).to eq(Gem::Version.new('17.5.2'))
      end

      it 'strips pre-release suffixes' do
        version = checker.parse_gitlab_version('17.5.2-pre')
        expect(version).to eq(Gem::Version.new('17.5.2'))
      end

      it 'strips whitespace from version' do
        version = checker.parse_gitlab_version("  17.5.2  \n")
        expect(version).to eq(Gem::Version.new('17.5.2'))
      end

      it 'extracts semantic version from complex version strings' do
        version = checker.parse_gitlab_version('17.5.2-rc1-ee')
        expect(version).to eq(Gem::Version.new('17.5.2'))
      end
    end

    context 'with invalid VERSION file' do
      it 'aborts when no valid semantic version is found' do
        expect { checker.parse_gitlab_version('invalid-version') }.to raise_error(SystemExit) do |error|
          expect(error.message).to match(/No valid semantic version found/)
        end
      end

      it 'aborts when VERSION file is empty' do
        expect { checker.parse_gitlab_version('') }.to raise_error(SystemExit) do |error|
          expect(error.message).to match(/No valid semantic version found/)
        end
      end
    end
  end

  describe '#parse_gitaly_version_from_gemfile_lock' do
    context 'with valid Gemfile.lock' do
      it 'parses gitaly version from Gemfile.lock' do
        version = checker.parse_gitaly_version('    gitaly (18.8.1)')
        expect(version).to eq(Gem::Version.new('18.8.1'))
      end
    end

    context 'with invalid Gemfile.lock' do
      it 'aborts when gitaly gem is not found' do
        content = "    otherstuff (18.8.1)"
        expect { checker.parse_gitaly_version(content) }.to raise_error(SystemExit) do |error|
          expect(error.message).to match(/Gitaly gem not found in Gemfile.lock/)
        end
      end

      it 'aborts when gitaly version is invalid' do
        content = "    gitaly (abc)"
        expect { checker.parse_gitaly_version(content) }.to raise_error(SystemExit) do |error|
          expect(error.message).to match(/Invalid Gitaly version format/)
        end
      end
    end
  end

  describe '#version_allowed?' do
    context 'with same major version' do
      it 'allows gitaly to be one minor version behind' do
        gitlab_version = Gem::Version.new('17.5.0')
        gitaly_version = Gem::Version.new('17.4.0')

        expect(checker.version_allowed?(gitlab_version, gitaly_version)).to be true
      end

      it 'allows gitaly to be multiple minor versions behind' do
        gitlab_version = Gem::Version.new('17.5.0')
        gitaly_version = Gem::Version.new('17.2.0')

        expect(checker.version_allowed?(gitlab_version, gitaly_version)).to be true
      end

      it 'rejects gitaly when same minor version' do
        gitlab_version = Gem::Version.new('17.5.0')
        gitaly_version = Gem::Version.new('17.5.0')

        expect(checker.version_allowed?(gitlab_version, gitaly_version)).to be false
      end

      it 'rejects gitaly when ahead by one minor version' do
        gitlab_version = Gem::Version.new('17.5.0')
        gitaly_version = Gem::Version.new('17.6.0')

        expect(checker.version_allowed?(gitlab_version, gitaly_version)).to be false
      end
    end

    context 'with different major versions' do
      it 'allows gitaly when major version is behind' do
        gitlab_version = Gem::Version.new('18.0.0')
        gitaly_version = Gem::Version.new('17.5.0')

        expect(checker.version_allowed?(gitlab_version, gitaly_version)).to be true
      end

      it 'rejects gitaly when major version is ahead' do
        gitlab_version = Gem::Version.new('17.5.0')
        gitaly_version = Gem::Version.new('18.0.0')

        expect(checker.version_allowed?(gitlab_version, gitaly_version)).to be false
      end
    end
  end
end
