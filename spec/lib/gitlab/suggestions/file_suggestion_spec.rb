# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Suggestions::FileSuggestion do
  def create_suggestion(new_line, to_content, lines_above = 0, lines_below = 0)
    position = Gitlab::Diff::Position.new(old_path: file_path,
      new_path: file_path,
      old_line: nil,
      new_line: new_line,
      diff_refs: merge_request.diff_refs)

    diff_note = create(:diff_note_on_merge_request,
      noteable: merge_request,
      position: position,
      project: project)

    create(:suggestion,
      :content_from_repo,
      note: diff_note,
      lines_above: lines_above,
      lines_below: lines_below,
      to_content: to_content)
  end

  let_it_be(:user) { create(:user) }

  let_it_be(:file_path) { 'files/ruby/popen.rb' }

  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:merge_request) do
    create(:merge_request, source_project: project, target_project: project)
  end

  let_it_be(:suggestion1) do
    create_suggestion(9, "      *** SUGGESTION 1 ***\n")
  end

  let_it_be(:suggestion2) do
    create_suggestion(15, "      *** SUGGESTION 2 ***\n")
  end

  let(:suggestions) { [suggestion1, suggestion2] }

  let(:file_suggestion) { described_class.new(file_path, suggestions) }

  describe '#line_conflict' do
    def stub_suggestions(line_index_spans)
      fake_suggestions = line_index_spans.map do |span|
        double("Suggestion",
          from_line_index: span[:from_line_index],
          to_line_index: span[:to_line_index])
      end

      allow(file_suggestion).to(receive(:suggestions).and_return(fake_suggestions))
    end

    context 'when line ranges do not overlap' do
      it 'return false' do
        stub_suggestions(
          [
            {
              from_line_index: 0,
              to_line_index: 10
            },
            {
              from_line_index: 11,
              to_line_index: 20
            }
          ]
        )

        expect(file_suggestion.line_conflict?).to be(false)
      end
    end

    context 'when line ranges are identical' do
      it 'returns true' do
        stub_suggestions(
          [
            {
              from_line_index: 0,
              to_line_index: 10
            },
            {
              from_line_index: 0,
              to_line_index: 10
            }
          ]
        )

        expect(file_suggestion.line_conflict?).to be(true)
      end
    end

    context 'when one range starts, and the other ends, on the same line' do
      it 'returns true' do
        stub_suggestions(
          [
            {
              from_line_index: 0,
              to_line_index: 10
            },
            {
              from_line_index: 10,
              to_line_index: 20
            }
          ]
        )

        expect(file_suggestion.line_conflict?).to be(true)
      end
    end

    context 'when one line range contains the other' do
      it 'returns true' do
        stub_suggestions(
          [
            {
              from_line_index: 0,
              to_line_index: 10
            },
            {
              from_line_index: 5,
              to_line_index: 7
            }
          ]
        )

        expect(file_suggestion.line_conflict?).to be(true)
      end
    end

    context 'when line ranges overlap' do
      it 'returns true' do
        stub_suggestions(
          [
            {
              from_line_index: 0,
              to_line_index: 10
            },
            {
              from_line_index: 8,
              to_line_index: 15
            }
          ]
        )

        expect(file_suggestion.line_conflict?).to be(true)
      end
    end

    context 'when no suggestions have been added' do
      it 'returns false' do
        expect(file_suggestion.line_conflict?).to be(false)
      end
    end
  end

  describe '#new_content' do
    context 'with two suggestions' do
      let(:suggestions) { [suggestion1, suggestion2] }

      it 'returns a blob with the suggestions applied to it' do
        expected_content = <<-CONTENT.strip_heredoc
          require 'fileutils'
          require 'open3'

          module Popen
            extend self

            def popen(cmd, path=nil)
              unless cmd.is_a?(Array)
                *** SUGGESTION 1 ***
              end

              path ||= Dir.pwd

              vars = {
                *** SUGGESTION 2 ***
              }

              options = {
                chdir: path
              }

              unless File.directory?(path)
                FileUtils.mkdir_p(path)
              end

              @cmd_output = ""
              @cmd_status = 0

              Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
                @cmd_output << stdout.read
                @cmd_output << stderr.read
                @cmd_status = wait_thr.value.exitstatus
              end

              return @cmd_output, @cmd_status
            end
          end
        CONTENT

        expect(file_suggestion.new_content).to eq(expected_content)
      end
    end

    context 'when no suggestions have been added' do
      let(:suggestions) { [] }

      it 'returns an empty string' do
        expect(file_suggestion.new_content).to eq('')
      end
    end

    context 'with multiline suggestions' do
      let(:suggestions) { [multi_suggestion1, multi_suggestion2, multi_suggestion3] }

      context 'when the previous suggestion increases the line count' do
        let!(:multi_suggestion1) do
          create_suggestion(9, "      *** SUGGESTION 1 ***\n      *** SECOND LINE ***\n      *** THIRD LINE ***\n")
        end

        let!(:multi_suggestion2) do
          create_suggestion(15, "      *** SUGGESTION 2 ***\n      *** SECOND LINE ***\n")
        end

        let!(:multi_suggestion3) do
          create_suggestion(19, "      chdir: *** SUGGESTION 3 ***\n")
        end

        it 'returns a blob with the suggestions applied to it' do
          expected_content = <<-CONTENT.strip_heredoc
          require 'fileutils'
          require 'open3'

          module Popen
            extend self

            def popen(cmd, path=nil)
              unless cmd.is_a?(Array)
                *** SUGGESTION 1 ***
                *** SECOND LINE ***
                *** THIRD LINE ***
              end

              path ||= Dir.pwd

              vars = {
                *** SUGGESTION 2 ***
                *** SECOND LINE ***
              }

              options = {
                chdir: *** SUGGESTION 3 ***
              }

              unless File.directory?(path)
                FileUtils.mkdir_p(path)
              end

              @cmd_output = ""
              @cmd_status = 0

              Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
                @cmd_output << stdout.read
                @cmd_output << stderr.read
                @cmd_status = wait_thr.value.exitstatus
              end

              return @cmd_output, @cmd_status
            end
          end
          CONTENT

          expect(file_suggestion.new_content).to eq(expected_content)
        end
      end

      context 'when the previous suggestion decreases and increases the line count' do
        let!(:multi_suggestion1) do
          create_suggestion(9, "    *** SUGGESTION 1 ***\n", 1, 1)
        end

        let!(:multi_suggestion2) do
          create_suggestion(15, "      *** SUGGESTION 2 ***\n      *** SECOND LINE ***\n")
        end

        let!(:multi_suggestion3) do
          create_suggestion(19, "      chdir: *** SUGGESTION 3 ***\n")
        end

        it 'returns a blob with the suggestions applied to it' do
          expected_content = <<-CONTENT.strip_heredoc
          require 'fileutils'
          require 'open3'

          module Popen
            extend self

            def popen(cmd, path=nil)
              *** SUGGESTION 1 ***

              path ||= Dir.pwd

              vars = {
                *** SUGGESTION 2 ***
                *** SECOND LINE ***
              }

              options = {
                chdir: *** SUGGESTION 3 ***
              }

              unless File.directory?(path)
                FileUtils.mkdir_p(path)
              end

              @cmd_output = ""
              @cmd_status = 0

              Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
                @cmd_output << stdout.read
                @cmd_output << stderr.read
                @cmd_status = wait_thr.value.exitstatus
              end

              return @cmd_output, @cmd_status
            end
          end
          CONTENT

          expect(file_suggestion.new_content).to eq(expected_content)
        end
      end

      context 'when the previous suggestion replaces with the same number of lines' do
        let!(:multi_suggestion1) do
          create_suggestion(9, "    *** SUGGESTION 1 ***\n    *** SECOND LINE ***\n    *** THIRD LINE ***\n", 1, 1)
        end

        let!(:multi_suggestion2) do
          create_suggestion(15, "      *** SUGGESTION 2 ***\n")
        end

        let!(:multi_suggestion3) do
          create_suggestion(19, "      chdir: *** SUGGESTION 3 ***\n")
        end

        it 'returns a blob with the suggestions applied to it' do
          expected_content = <<-CONTENT.strip_heredoc
          require 'fileutils'
          require 'open3'

          module Popen
            extend self

            def popen(cmd, path=nil)
              *** SUGGESTION 1 ***
              *** SECOND LINE ***
              *** THIRD LINE ***

              path ||= Dir.pwd

              vars = {
                *** SUGGESTION 2 ***
              }

              options = {
                chdir: *** SUGGESTION 3 ***
              }

              unless File.directory?(path)
                FileUtils.mkdir_p(path)
              end

              @cmd_output = ""
              @cmd_status = 0

              Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
                @cmd_output << stdout.read
                @cmd_output << stderr.read
                @cmd_status = wait_thr.value.exitstatus
              end

              return @cmd_output, @cmd_status
            end
          end
          CONTENT

          expect(file_suggestion.new_content).to eq(expected_content)
        end
      end

      context 'when the previous suggestion replaces multiple lines and the suggestions were applied out of order' do
        let(:suggestions) { [multi_suggestion1, multi_suggestion3, multi_suggestion2] }

        let!(:multi_suggestion1) do
          create_suggestion(9, "    *** SUGGESTION 1 ***\n    *** SECOND LINE ***\n    *** THIRD LINE ***\n", 1, 1)
        end

        let!(:multi_suggestion3) do
          create_suggestion(19, "    *** SUGGESTION 3 ***\n", 1, 1)
        end

        let!(:multi_suggestion2) do
          create_suggestion(15, "    *** SUGGESTION 2 ***\n", 1, 1)
        end

        it 'returns a blob with the suggestions applied to it' do
          expected_content = <<-CONTENT.strip_heredoc
          require 'fileutils'
          require 'open3'

          module Popen
            extend self

            def popen(cmd, path=nil)
              *** SUGGESTION 1 ***
              *** SECOND LINE ***
              *** THIRD LINE ***

              path ||= Dir.pwd

              *** SUGGESTION 2 ***

              *** SUGGESTION 3 ***

              unless File.directory?(path)
                FileUtils.mkdir_p(path)
              end

              @cmd_output = ""
              @cmd_status = 0

              Open3.popen3(vars, *cmd, options) do |stdin, stdout, stderr, wait_thr|
                @cmd_output << stdout.read
                @cmd_output << stderr.read
                @cmd_status = wait_thr.value.exitstatus
              end

              return @cmd_output, @cmd_status
            end
          end
          CONTENT

          expect(file_suggestion.new_content).to eq(expected_content)
        end
      end
    end
  end
end
