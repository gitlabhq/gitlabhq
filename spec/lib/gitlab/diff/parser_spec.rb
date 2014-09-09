require 'spec_helper'

describe Gitlab::Diff::Parser do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:commit) { project.repository.commit(sample_commit.id) }
  let(:diff) { commit.diffs.first }
  let(:parser) { Gitlab::Diff::Parser.new }

  describe :parse do
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
      @lines = parser.parse(diff.lines)
    end

    it { @lines.size.should == 30 }

    describe 'lines' do
      describe 'first line' do
        let(:line) { @lines.first }

        it { line.type.should == 'match' }
        it { line.old_pos.should == 6 }
        it { line.new_pos.should == 6 }
        it { line.text.should == '@@ -6,12 +6,18 @@ module Popen' }
      end

      describe 'removal line' do
        let(:line) { @lines[10] }

        it { line.type.should == 'old' }
        it { line.old_pos.should == 14 }
        it { line.new_pos.should == 13 }
        it { line.text.should == '-    options = { chdir: path }' }
      end

      describe 'addition line' do
        let(:line) { @lines[16] }

        it { line.type.should == 'new' }
        it { line.old_pos.should == 15 }
        it { line.new_pos.should == 18 }
        it { line.text.should == '+    options = {' }
      end

      describe 'unchanged line' do
        let(:line) { @lines.last }

        it { line.type.should == nil }
        it { line.old_pos.should == 24 }
        it { line.new_pos.should == 31 }
        it { line.text.should == '       @cmd_output &lt;&lt; stderr.read' }
      end
    end
  end
end
