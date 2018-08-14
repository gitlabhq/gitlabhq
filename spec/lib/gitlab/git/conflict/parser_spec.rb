require 'spec_helper'

describe Gitlab::Git::Conflict::Parser do
  describe '.parse' do
    def parse_text(text)
      described_class.parse(text, our_path: 'README.md', their_path: 'README.md')
    end

    context 'when the file has valid conflicts' do
      let(:text) do
        <<CONFLICT
module Gitlab
  module Regexp
    extend self

    def username_regexp
      default_regexp
    end

<<<<<<< files/ruby/regex.rb
    def project_name_regexp
      /\A[a-zA-Z0-9][a-zA-Z0-9_\-\. ]*\z/
    end

    def name_regexp
      /\A[a-zA-Z0-9_\-\. ]*\z/
=======
    def project_name_regex
      %r{\A[a-zA-Z0-9][a-zA-Z0-9_\-\. ]*\z}
    end

    def name_regex
      %r{\A[a-zA-Z0-9_\-\. ]*\z}
>>>>>>> files/ruby/regex.rb
    end

    def path_regexp
      default_regexp
    end

<<<<<<< files/ruby/regex.rb
    def archive_formats_regexp
      /(zip|tar|7z|tar\.gz|tgz|gz|tar\.bz2|tbz|tbz2|tb2|bz2)/
=======
    def archive_formats_regex
      %r{(zip|tar|7z|tar\.gz|tgz|gz|tar\.bz2|tbz|tbz2|tb2|bz2)}
>>>>>>> files/ruby/regex.rb
    end

    def git_reference_regexp
      # Valid git ref regexp, see:
      # https://www.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html
      %r{
        (?!
           (?# doesn't begins with)
           \/|                    (?# rule #6)
           (?# doesn't contain)
           .*(?:
              [\/.]\.|            (?# rule #1,3)
              \/\/|               (?# rule #6)
              @\{|                (?# rule #8)
              \\                  (?# rule #9)
           )
        )
        [^\000-\040\177~^:?*\[]+  (?# rule #4-5)
        (?# doesn't end with)
        (?<!\.lock)               (?# rule #1)
        (?<![\/.])                (?# rule #6-7)
      }x
    end

    protected

<<<<<<< files/ruby/regex.rb
    def default_regexp
      /\A[.?]?[a-zA-Z0-9][a-zA-Z0-9_\-\.]*(?<!\.git)\z/
=======
    def default_regex
      %r{\A[.?]?[a-zA-Z0-9][a-zA-Z0-9_\-\.]*(?<!\.git)\z}
>>>>>>> files/ruby/regex.rb
    end
  end
end
CONFLICT
      end

      let(:lines) do
        described_class.parse(text, our_path: 'files/ruby/regex.rb', their_path: 'files/ruby/regex.rb')
      end
      let(:old_line_numbers) do
        lines.select { |line| line[:type] != 'new' }.map { |line| line[:line_old] }
      end
      let(:new_line_numbers) do
        lines.select { |line| line[:type] != 'old' }.map { |line| line[:line_new] }
      end
      let(:line_indexes) { lines.map { |line| line[:line_obj_index] } }

      it 'sets our lines as new lines' do
        expect(lines[8..13]).to all(include(type: 'new'))
        expect(lines[26..27]).to all(include(type: 'new'))
        expect(lines[56..57]).to all(include(type: 'new'))
      end

      it 'sets their lines as old lines' do
        expect(lines[14..19]).to all(include(type: 'old'))
        expect(lines[28..29]).to all(include(type: 'old'))
        expect(lines[58..59]).to all(include(type: 'old'))
      end

      it 'sets non-conflicted lines as both' do
        expect(lines[0..7]).to all(include(type: nil))
        expect(lines[20..25]).to all(include(type: nil))
        expect(lines[30..55]).to all(include(type: nil))
        expect(lines[60..62]).to all(include(type: nil))
      end

      it 'sets consecutive line numbers for line_obj_index, line_old, and line_new' do
        expect(line_indexes).to eq(0.upto(62).to_a)
        expect(old_line_numbers).to eq(1.upto(53).to_a)
        expect(new_line_numbers).to eq(1.upto(53).to_a)
      end
    end

    context 'when the file contents include conflict delimiters' do
      context 'when there is a non-start delimiter first' do
        it 'raises UnexpectedDelimiter when there is a middle delimiter first' do
          expect { parse_text('=======') }
            .to raise_error(Gitlab::Git::Conflict::Parser::UnexpectedDelimiter)
        end

        it 'raises UnexpectedDelimiter when there is an end delimiter first' do
          expect { parse_text('>>>>>>> README.md') }
            .to raise_error(Gitlab::Git::Conflict::Parser::UnexpectedDelimiter)
        end

        it 'does not raise when there is an end delimiter for a different path first' do
          expect { parse_text('>>>>>>> some-other-path.md') }
            .not_to raise_error
        end
      end

      context 'when a start delimiter is followed by a non-middle delimiter' do
        let(:start_text) { "<<<<<<< README.md\n" }
        let(:end_text) { "\n=======\n>>>>>>> README.md" }

        it 'raises UnexpectedDelimiter when it is followed by an end delimiter' do
          expect { parse_text(start_text + '>>>>>>> README.md' + end_text) }
            .to raise_error(Gitlab::Git::Conflict::Parser::UnexpectedDelimiter)
        end

        it 'raises UnexpectedDelimiter when it is followed by another start delimiter' do
          expect { parse_text(start_text + start_text + end_text) }
            .to raise_error(Gitlab::Git::Conflict::Parser::UnexpectedDelimiter)
        end

        it 'does not raise when it is followed by a start delimiter for a different path' do
          expect { parse_text(start_text + '>>>>>>> some-other-path.md' + end_text) }
            .not_to raise_error
        end
      end

      context 'when a middle delimiter is followed by a non-end delimiter' do
        let(:start_text) { "<<<<<<< README.md\n=======\n" }
        let(:end_text) { "\n>>>>>>> README.md" }

        it 'raises UnexpectedDelimiter when it is followed by another middle delimiter' do
          expect { parse_text(start_text + '=======' + end_text) }
            .to raise_error(Gitlab::Git::Conflict::Parser::UnexpectedDelimiter)
        end

        it 'raises UnexpectedDelimiter when it is followed by a start delimiter' do
          expect { parse_text(start_text + start_text + end_text) }
            .to raise_error(Gitlab::Git::Conflict::Parser::UnexpectedDelimiter)
        end

        it 'does not raise when it is followed by a start delimiter for another path' do
          expect { parse_text(start_text + '<<<<<<< some-other-path.md' + end_text) }
            .not_to raise_error
        end
      end

      it 'raises MissingEndDelimiter when there is no end delimiter at the end' do
        start_text = "<<<<<<< README.md\n=======\n"

        expect { parse_text(start_text) }
          .to raise_error(Gitlab::Git::Conflict::Parser::MissingEndDelimiter)

        expect { parse_text(start_text + '>>>>>>> some-other-path.md') }
          .to raise_error(Gitlab::Git::Conflict::Parser::MissingEndDelimiter)
      end
    end

    context 'other file types' do
      it 'raises UnmergeableFile when lines is blank, indicating a binary file' do
        expect { parse_text('') }
          .to raise_error(Gitlab::Git::Conflict::Parser::UnmergeableFile)

        expect { parse_text(nil) }
          .to raise_error(Gitlab::Git::Conflict::Parser::UnmergeableFile)
      end

      it 'raises UnmergeableFile when the file is over 200 KB' do
        expect { parse_text('a' * 204801) }
          .to raise_error(Gitlab::Git::Conflict::Parser::UnmergeableFile)
      end

      # All text from Rugged has an encoding of ASCII_8BIT, so force that in
      # these strings.
      context 'when the file contains UTF-8 characters' do
        it 'does not raise' do
          expect { parse_text("Espa\xC3\xB1a".force_encoding(Encoding::ASCII_8BIT)) }
            .not_to raise_error
        end
      end
    end
  end
end
