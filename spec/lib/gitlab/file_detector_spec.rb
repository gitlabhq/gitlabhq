# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::FileDetector do
  describe '.types_in_paths' do
    it 'returns the file types for the given paths' do
      expect(described_class.types_in_paths(%w(README.md CHANGELOG VERSION VERSION)))
        .to eq(%i{readme changelog version})
    end

    it 'does not include unrecognized file paths' do
      expect(described_class.types_in_paths(%w(README.md foo.txt)))
        .to eq(%i{readme})
    end
  end

  describe '.type_of' do
    it 'returns the type of a README file' do
      filenames = Gitlab::MarkupHelper::PLAIN_FILENAMES + Gitlab::MarkupHelper::PLAIN_FILENAMES.map(&:upcase)
      extensions = Gitlab::MarkupHelper::EXTENSIONS + Gitlab::MarkupHelper::EXTENSIONS.map(&:upcase)

      filenames.each do |filename|
        expect(described_class.type_of(filename)).to eq(:readme)

        extensions.each do |extname|
          expect(described_class.type_of("#{filename}.#{extname}")).to eq(:readme)
        end
      end
    end

    it 'returns nil for a README.rb file' do
      expect(described_class.type_of('README.rb')).to be_nil
    end

    it 'returns nil for a README file in a directory' do
      expect(described_class.type_of('foo/README.md')).to be_nil
    end

    it 'returns the type of a changelog file' do
      %w(CHANGELOG HISTORY CHANGES NEWS).each do |file|
        expect(described_class.type_of(file)).to eq(:changelog)
      end
    end

    it 'returns the type of a license file' do
      %w(LICENSE LICENCE COPYING UNLICENSE UNLICENCE).each do |file|
        expect(described_class.type_of(file)).to eq(:license)
      end
    end

    it 'returns nil for an UNCOPYING file' do
      expect(described_class.type_of('UNCOPYING')).to be_nil
    end

    it 'returns the type of a version file' do
      expect(described_class.type_of('VERSION')).to eq(:version)
    end

    it 'returns the type of a .gitignore file' do
      expect(described_class.type_of('.gitignore')).to eq(:gitignore)
    end

    it 'returns the type of a GitLab CI config file' do
      expect(described_class.type_of('.gitlab-ci.yml')).to eq(:gitlab_ci)
    end

    it 'returns the type of an avatar' do
      %w(logo.gif logo.png logo.jpg).each do |file|
        expect(described_class.type_of(file)).to eq(:avatar)
      end
    end

    it 'returns the type of an issue template' do
      expect(described_class.type_of('.gitlab/issue_templates/foo.md')).to eq(:issue_template)
    end

    it 'returns the type of a merge request template' do
      expect(described_class.type_of('.gitlab/merge_request_templates/foo.md')).to eq(:merge_request_template)
    end

    it 'returns nil for an unknown file' do
      expect(described_class.type_of('foo.txt')).to be_nil
    end
  end
end
