# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Changelog::Generator do
  describe '#add' do
    let(:project) { build_stubbed(:project) }
    let(:author) { build_stubbed(:user) }
    let(:commit) { build_stubbed(:commit) }
    let(:config) { Gitlab::Changelog::Config.new(project) }

    it 'generates the Markdown for the first release' do
      release = Gitlab::Changelog::Release.new(
        version: '1.0.0',
        date: Time.utc(2021, 1, 5),
        config: config
      )

      release.add_entry(
        title: 'This is a new change',
        commit: commit,
        category: 'added',
        author: author
      )

      gen = described_class.new('')

      expect(gen.add(release)).to eq(<<~MARKDOWN)
        ## 1.0.0 (2021-01-05)

        ### added (1 change)

        - [This is a new change](#{Gitlab::UrlBuilder.build(commit)})
      MARKDOWN
    end

    it 'generates the Markdown for a newer release' do
      release = Gitlab::Changelog::Release.new(
        version: '2.0.0',
        date: Time.utc(2021, 1, 5),
        config: config
      )

      release.add_entry(
        title: 'This is a new change',
        commit: commit,
        category: 'added',
        author: author
      )

      gen = described_class.new(<<~MARKDOWN)
        This is a changelog file.

        ## 1.0.0

        This is the changelog for version 1.0.0.
      MARKDOWN

      expect(gen.add(release)).to eq(<<~MARKDOWN)
        This is a changelog file.

        ## 2.0.0 (2021-01-05)

        ### added (1 change)

        - [This is a new change](#{Gitlab::UrlBuilder.build(commit)})

        ## 1.0.0

        This is the changelog for version 1.0.0.
      MARKDOWN
    end

    it 'generates the Markdown for a patch release' do
      release = Gitlab::Changelog::Release.new(
        version: '1.1.0',
        date: Time.utc(2021, 1, 5),
        config: config
      )

      release.add_entry(
        title: 'This is a new change',
        commit: commit,
        category: 'added',
        author: author
      )

      gen = described_class.new(<<~MARKDOWN)
        This is a changelog file.

        ## 2.0.0

        This is another release.

        ## 1.0.0

        This is the changelog for version 1.0.0.
      MARKDOWN

      expect(gen.add(release)).to eq(<<~MARKDOWN)
        This is a changelog file.

        ## 2.0.0

        This is another release.

        ## 1.1.0 (2021-01-05)

        ### added (1 change)

        - [This is a new change](#{Gitlab::UrlBuilder.build(commit)})

        ## 1.0.0

        This is the changelog for version 1.0.0.
      MARKDOWN
    end

    it 'generates the Markdown for an old release' do
      release = Gitlab::Changelog::Release.new(
        version: '0.5.0',
        date: Time.utc(2021, 1, 5),
        config: config
      )

      release.add_entry(
        title: 'This is a new change',
        commit: commit,
        category: 'added',
        author: author
      )

      gen = described_class.new(<<~MARKDOWN)
        This is a changelog file.

        ## 2.0.0

        This is another release.

        ## 1.0.0

        This is the changelog for version 1.0.0.
      MARKDOWN

      expect(gen.add(release)).to eq(<<~MARKDOWN)
        This is a changelog file.

        ## 2.0.0

        This is another release.

        ## 1.0.0

        This is the changelog for version 1.0.0.

        ## 0.5.0 (2021-01-05)

        ### added (1 change)

        - [This is a new change](#{Gitlab::UrlBuilder.build(commit)})
      MARKDOWN
    end
  end
end
