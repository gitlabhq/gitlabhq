# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/git_diff_parser'

RSpec.describe Keeps::Helpers::GitDiffParser, feature_category: :tooling do
  let(:parser) { described_class.new }

  describe '#all_changed_files' do
    let(:diff) do
      <<~DIFF
      diff --git a/foo.txt b/bar.txt
      similarity index 100%
      rename from foo.txt
      rename to bar.txt
      diff --git a/boo.txt b/boo.txt
      new file mode 100644
      index 000000000000..e69de29bb2d1
      diff --git a/boobar.txt b/boobar.txt
      deleted file mode 100644
      index 60b20b312e05..000000000000
      --- a/boobar.txt
      +++ /dev/null
      @@ -1 +0,0 @@
      -something blah blah
      diff --git a/foobar.txt b/foobar.txt
      index 2ef267e25bd6..0fecdb8e98f3 100644
      --- a/foobar.txt
      +++ b/foobar.txt
      @@ -1 +1 @@
      -some content
      +some content updated
      DIFF
    end

    it 'returns all the files mentioned in the diff' do
      expect(parser.all_changed_files(diff)).to contain_exactly(
        'foo.txt',
        'bar.txt',
        'foobar.txt',
        'boo.txt',
        'boobar.txt'
      )
    end
  end
end
