# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::Parser do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.raw_diffs.first }
  let(:parser) { described_class.new }

  describe '#parse' do
    let(:diff) do
      <<eos
--- a/files/ruby/popen.rb
+++ b/files/ruby/popen.rb
@@ -6,12 +6,18 @@ module Popen

   def popen(cmd, path=nil)
     unless cmd.is_a?(Array)
-      raise "System commands must be given as an array of strings"
+      raise RuntimeError, "System commands must be given as an array of strings"
     end

     path ||= Dir.pwd
-    vars = { "PWD" => path }
-    options = { chdir: path }
+
+    vars = {
+      "PWD" => path
+    }
+
+    options = {
+      chdir: path
+    }

     unless File.directory?(path)
       FileUtils.mkdir_p(path)
@@ -19,6 +25,7 @@ module Popen

     @cmd_output = ""
     @cmd_status = 0
+
     Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
       @cmd_output << stdout.read
       @cmd_output << stderr.read
eos
    end

    before do
      @lines = parser.parse(diff.lines).to_a
    end

    it { expect(@lines.size).to eq(30) }

    describe 'lines' do
      describe 'first line' do
        let(:line) { @lines.first }

        it { expect(line.type).to eq('match') }
        it { expect(line.old_pos).to eq(6) }
        it { expect(line.new_pos).to eq(6) }
        it { expect(line.text).to eq('@@ -6,12 +6,18 @@ module Popen') }
      end

      describe 'removal line' do
        let(:line) { @lines[10] }

        it { expect(line.type).to eq('old') }
        it { expect(line.old_pos).to eq(14) }
        it { expect(line.new_pos).to eq(13) }
        it { expect(line.text).to eq('-    options = { chdir: path }') }
      end

      describe 'addition line' do
        let(:line) { @lines[16] }

        it { expect(line.type).to eq('new') }
        it { expect(line.old_pos).to eq(15) }
        it { expect(line.new_pos).to eq(18) }
        it { expect(line.text).to eq('+    options = {') }
      end

      describe 'unchanged line' do
        let(:line) { @lines.last }

        it { expect(line.type).to eq(nil) }
        it { expect(line.old_pos).to eq(24) }
        it { expect(line.new_pos).to eq(31) }
        it { expect(line.text).to eq('       @cmd_output << stderr.read') }
      end
    end
  end

  describe '\ No newline at end of file' do
    it "parses nonewline in one file correctly" do
      first_nonewline_diff = <<~END
        --- a/test
        +++ b/test
        @@ -1,2 +1,2 @@
        +ipsum
         lorem
        -ipsum
        \\ No newline at end of file
      END
      lines = parser.parse(first_nonewline_diff.lines).to_a

      expect(lines[0].type).to eq('new')
      expect(lines[0].text).to eq('+ipsum')
      expect(lines[2].type).to eq('old')
      expect(lines[3].type).to eq('old-nonewline')
      expect(lines[1].old_pos).to eq(1)
      expect(lines[1].new_pos).to eq(2)
    end

    it "parses nonewline in two files correctly" do
      both_nonewline_diff = <<~END
        --- a/test
        +++ b/test
        @@ -1,2 +1,2 @@
        -lorem
        -ipsum
        \\ No newline at end of file
        +ipsum
        +lorem
        \\ No newline at end of file
      END
      lines = parser.parse(both_nonewline_diff.lines).to_a

      expect(lines[0].type).to eq('old')
      expect(lines[1].type).to eq('old')
      expect(lines[2].type).to eq('old-nonewline')
      expect(lines[5].type).to eq('new-nonewline')
      expect(lines[3].text).to eq('+ipsum')
      expect(lines[3].old_pos).to eq(3)
      expect(lines[3].new_pos).to eq(1)
      expect(lines[4].text).to eq('+lorem')
      expect(lines[4].old_pos).to eq(3)
      expect(lines[4].new_pos).to eq(2)
    end
  end

  context 'when lines is empty' do
    it { expect(parser.parse([])).to eq([]) }
    it { expect(parser.parse(nil)).to eq([]) }
  end

  context 'when it is a binary notice' do
    let(:diff)  do
      <<~END
        Binary files a/test and b/test differ
      END
    end

    it { expect(parser.parse(diff.each_line)).to eq([]) }
  end

  describe 'tolerates special diff markers in a content' do
    it "counts lines correctly" do
      diff = <<~END
        --- a/test
        +++ b/test
        @@ -1,2 +1,2 @@
        +ipsum
        +++ b
        -ipsum
      END

      lines = parser.parse(diff.lines).to_a

      expect(lines.size).to eq(3)
    end
  end
end
