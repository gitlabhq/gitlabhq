# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::SuggestionsParser do
  describe '.parse' do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.project }
    let(:position) do
      Gitlab::Diff::Position.new(old_path: "files/ruby/popen.rb",
                                 new_path: "files/ruby/popen.rb",
                                 old_line: nil,
                                 new_line: 9,
                                 diff_refs: merge_request.diff_refs)
    end

    let(:diff_file) do
      position.diff_file(project.repository)
    end

    subject do
      described_class.parse(markdown, project: merge_request.project,
                                      position: position)
    end

    def blob_lines_data(from_line, to_line)
      diff_file.new_blob_lines_between(from_line, to_line).join
    end

    context 'single-line suggestions' do
      let(:markdown) do
        <<-MARKDOWN.strip_heredoc
          ```suggestion
            foo
            bar
          ```

          ```
            nothing
          ```

          ```suggestion
            xpto
            baz
          ```

          ```thing
            this is not a suggestion, it's a thing
          ```
        MARKDOWN
      end

      it 'returns a list of Gitlab::Diff::Suggestion' do
        expect(subject).to all(be_a(Gitlab::Diff::Suggestion))
        expect(subject.size).to eq(2)
      end

      it 'parsed suggestion has correct data' do
        from_line = position.new_line
        to_line = position.new_line

        expect(subject.first.to_hash).to include(from_content: blob_lines_data(from_line, to_line),
                                                 to_content: "  foo\n  bar\n",
                                                 lines_above: 0,
                                                 lines_below: 0)

        expect(subject.second.to_hash).to include(from_content: blob_lines_data(from_line, to_line),
                                                  to_content: "  xpto\n  baz\n",
                                                  lines_above: 0,
                                                  lines_below: 0)
      end
    end

    context 'multi-line suggestions' do
      let(:markdown) do
        <<-MARKDOWN.strip_heredoc
          ```suggestion:-2+1
            # above and below
          ```

          ```
            nothing
          ```

          ```suggestion:-3
            # only above
          ```

          ```suggestion:+3
            # only below
          ```

          ```thing
            this is not a suggestion, it's a thing
          ```
        MARKDOWN
      end

      it 'returns a list of Gitlab::Diff::Suggestion' do
        expect(subject).to all(be_a(Gitlab::Diff::Suggestion))
        expect(subject.size).to eq(3)
      end

      it 'suggestion with above and below param has correct data' do
        from_line = position.new_line - 2
        to_line = position.new_line + 1

        expect(subject.first.to_hash).to include(from_content: blob_lines_data(from_line, to_line),
                                                 to_content: "  # above and below\n",
                                                 lines_above: 2,
                                                 lines_below: 1)
      end

      it 'suggestion with above param has correct data' do
        from_line = position.new_line - 3
        to_line = position.new_line

        expect(subject.second.to_hash).to eq(from_content: blob_lines_data(from_line, to_line),
                                             to_content: "  # only above\n",
                                             lines_above: 3,
                                             lines_below: 0)
      end

      it 'suggestion with below param has correct data' do
        from_line = position.new_line
        to_line = position.new_line + 3

        expect(subject.third.to_hash).to eq(from_content: blob_lines_data(from_line, to_line),
                                            to_content: "  # only below\n",
                                            lines_above: 0,
                                            lines_below: 3)
      end
    end
  end
end
