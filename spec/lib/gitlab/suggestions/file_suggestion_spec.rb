# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Suggestions::FileSuggestion do
  def create_suggestion(new_line, to_content)
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
           to_content: to_content)
  end

  let_it_be(:user) { create(:user) }

  let_it_be(:file_path) { 'files/ruby/popen.rb'}

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

  let(:file_suggestion) { described_class.new }

  describe '#add_suggestion' do
    it 'succeeds when adding a suggestion for the same file as the original' do
      file_suggestion.add_suggestion(suggestion1)

      expect { file_suggestion.add_suggestion(suggestion2) }.not_to raise_error
    end

    it 'raises an error when adding a suggestion for a different file' do
      allow(suggestion2)
        .to(receive_message_chain(:diff_file, :file_path)
        .and_return('path/to/different/file'))

      file_suggestion.add_suggestion(suggestion1)

      expect { file_suggestion.add_suggestion(suggestion2) }.to(
        raise_error(described_class::SuggestionForDifferentFileError)
      )
    end
  end

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
    it 'returns a blob with the suggestions applied to it' do
      file_suggestion.add_suggestion(suggestion1)
      file_suggestion.add_suggestion(suggestion2)

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

    it 'returns an empty string when no suggestions have been added' do
      expect(file_suggestion.new_content).to eq('')
    end
  end

  describe '#file_path' do
    it 'returns the path of the file associated with the suggestions' do
      file_suggestion.add_suggestion(suggestion1)

      expect(file_suggestion.file_path).to eq(file_path)
    end

    it 'returns nil if no suggestions have been added' do
      expect(file_suggestion.file_path).to be(nil)
    end
  end
end
