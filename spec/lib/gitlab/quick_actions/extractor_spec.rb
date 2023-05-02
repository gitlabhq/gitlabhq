# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QuickActions::Extractor, feature_category: :team_planning do
  let(:definitions) do
    Class.new do
      include Gitlab::QuickActions::Dsl

      command(:reopen, :open) {}
      command(:assign) {}
      command(:labels) {}
      command(:power) {}
      command(:noop_command)
      substitution(:substitution) { 'foo' }
      substitution :shrug do |comment|
        "#{comment} SHRUG"
      end
    end.command_definitions
  end

  let(:extractor) { described_class.new(definitions, keep_actions: keep_actions) }
  let(:keep_actions) { false }

  shared_examples 'command with no argument' do
    it 'extracts command' do
      msg, commands = extractor.extract_commands(original_msg)

      expect(commands).to eq [['reopen']]
      expect(msg).to eq final_msg
    end
  end

  shared_examples 'command with a single argument' do
    it 'extracts command' do
      msg, commands = extractor.extract_commands(original_msg)

      expect(commands).to eq [['assign', '@joe']]
      expect(msg).to eq final_msg
    end
  end

  shared_examples 'command with multiple arguments' do
    it 'extracts command' do
      msg, commands = extractor.extract_commands(original_msg)

      expect(commands).to eq [['labels', '~foo ~"bar baz" label']]
      expect(msg).to eq final_msg
    end
  end

  describe '#extract_commands' do
    describe 'command with no argument' do
      context 'at the start of content' do
        it_behaves_like 'command with no argument' do
          let(:original_msg) { "/reopen\nworld" }
          let(:final_msg) { "world" }
        end
      end

      context 'in the middle of content' do
        it_behaves_like 'command with no argument' do
          let(:original_msg) { "hello\n/reopen\nworld" }
          let(:final_msg) { "hello\nworld" }
        end
      end

      context 'in the middle of a line' do
        it 'does not extract command' do
          msg = "hello\nworld /reopen"
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq "hello\nworld /reopen"
        end
      end

      context 'at the end of content' do
        it_behaves_like 'command with no argument' do
          let(:original_msg) { "hello\n/reopen" }
          let(:final_msg) { "hello" }
        end
      end
    end

    describe 'command with a single argument' do
      context 'at the start of content' do
        it_behaves_like 'command with a single argument' do
          let(:original_msg) { "/assign @joe\nworld" }
          let(:final_msg) { "world" }
        end

        it 'allows slash in command arguments' do
          msg = "/assign @joe / @jane\nworld"
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to eq [['assign', '@joe / @jane']]
          expect(msg).to eq 'world'
        end
      end

      context 'in the middle of content' do
        it_behaves_like 'command with a single argument' do
          let(:original_msg) { "hello\n/assign @joe\nworld" }
          let(:final_msg) { "hello\nworld" }
        end
      end

      context 'in the middle of a line' do
        it 'does not extract command' do
          msg = "hello\nworld /assign @joe"
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq "hello\nworld /assign @joe"
        end
      end

      context 'at the end of content' do
        it_behaves_like 'command with a single argument' do
          let(:original_msg) { "hello\n/assign @joe" }
          let(:final_msg) { "hello" }
        end
      end

      context 'when argument is not separated with a space' do
        it 'does not extract command' do
          msg = "hello\n/assign@joe\nworld"
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq "hello\n/assign@joe\nworld"
        end
      end
    end

    describe 'command with multiple arguments' do
      context 'at the start of content' do
        it_behaves_like 'command with multiple arguments' do
          let(:original_msg) { %(/labels ~foo ~"bar baz" label\nworld) }
          let(:final_msg) { "world" }
        end
      end

      context 'in the middle of content' do
        it_behaves_like 'command with multiple arguments' do
          let(:original_msg) { %(hello\n/labels ~foo ~"bar baz" label\nworld) }
          let(:final_msg) { "hello\nworld" }
        end
      end

      context 'in the middle of a line' do
        it 'does not extract command' do
          msg = %(hello\nworld /labels ~foo ~"bar baz" label)
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq %(hello\nworld /labels ~foo ~"bar baz" label)
        end
      end

      context 'at the end of content' do
        it_behaves_like 'command with multiple arguments' do
          let(:original_msg) { %(hello\n/labels ~foo ~"bar baz" label) }
          let(:final_msg) { "hello" }
        end
      end

      context 'when argument is not separated with a space' do
        it 'does not extract command' do
          msg = %(hello\n/labels~foo ~"bar baz" label\nworld)
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq %(hello\n/labels~foo ~"bar baz" label\nworld)
        end
      end
    end

    describe 'command with keep_actions' do
      let(:keep_actions) { true }

      context 'at the start of content' do
        it_behaves_like 'command with a single argument' do
          let(:original_msg) { "/assign @joe\nworld" }
          let(:final_msg) { "\n/assign @joe\n\nworld" }
        end
      end

      context 'in the middle of content' do
        it_behaves_like 'command with a single argument' do
          let(:original_msg) { "hello\n/assign @joe\nworld" }
          let(:final_msg) { "hello\n\n/assign @joe\n\nworld" }
        end
      end

      context 'at the end of content' do
        it_behaves_like 'command with a single argument' do
          let(:original_msg) { "hello\n/assign @joe" }
          let(:final_msg) { "hello\n\n/assign @joe" }
        end
      end
    end

    it 'extracts command with multiple arguments and various prefixes' do
      msg = %(hello\n/power @user.name %9.10 ~"bar baz.2"\nworld)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['power', '@user.name %9.10 ~"bar baz.2"']]
      expect(msg).to eq "hello\nworld"
    end

    it 'extracts command case insensitive' do
      msg = %(hello\n/PoWer @user.name %9.10 ~"bar baz.2"\nworld)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['power', '@user.name %9.10 ~"bar baz.2"']]
      expect(msg).to eq "hello\nworld"
    end

    it 'does not extract noop commands' do
      msg = %(hello\nworld\n/reopen\n/noop_command)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['reopen']]
      expect(msg).to eq "hello\nworld\n/noop_command"
    end

    it 'extracts and performs substitution commands' do
      msg = %(hello\nworld\n/reopen\n/substitution)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['reopen'], ['substitution']]
      expect(msg).to eq "hello\nworld\nfoo"
    end

    it 'extracts and performs substitution commands' do
      msg = %(hello\nworld\n/reopen\n/shrug this is great?)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['reopen'], ['shrug', 'this is great?']]
      expect(msg).to eq "hello\nworld\nthis is great? SHRUG"
    end

    it 'extracts and performs multiple substitution commands' do
      msg = %(hello\nworld\n/reopen\n/shrug this is great?\n/shrug meh)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['reopen'], ['shrug', 'this is great?'], %w(shrug meh)]
      expect(msg).to eq "hello\nworld\nthis is great? SHRUG\nmeh SHRUG"
    end

    it 'does not extract substitution command in inline code' do
      msg = %(hello\nworld\n/reopen\n`/tableflip this is great`?)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['reopen']]
      expect(msg).to eq "hello\nworld\n`/tableflip this is great`?"
    end

    it 'extracts and performs substitution commands case insensitive' do
      msg = %(hello\nworld\n/reOpen\n/sHRuG this is great?)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['reopen'], ['shrug', 'this is great?']]
      expect(msg).to eq "hello\nworld\nthis is great? SHRUG"
    end

    it 'extracts and performs substitution commands with comments' do
      msg = %(hello\nworld\n/reopen\n/substitution wow this is a thing.)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to match_array [['reopen'], ['substitution', 'wow this is a thing.']]
      expect(msg).to eq "hello\nworld\nfoo"
    end

    it 'extracts and performs substitution commands with keep_actions' do
      extractor = described_class.new(definitions, keep_actions: true)
      msg = %(hello\nworld\n/reopen\n/substitution wow this is a thing.)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to match_array [['reopen'], ['substitution', 'wow this is a thing.']]
      expect(msg).to eq "hello\nworld\n\n/reopen\n\nfoo"
    end

    it 'extracts multiple commands' do
      msg = %(hello\n/power @user.name %9.10 ~"bar baz.2" label\nworld\n/reopen)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['power', '@user.name %9.10 ~"bar baz.2" label'], ['reopen']]
      expect(msg).to eq "hello\nworld"
    end

    it 'does not alter original content if no command is found' do
      msg = 'Fixes #123'
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq 'Fixes #123'
    end

    it 'does not get confused if command comes before an inline code' do
      msg = "/reopen\n`some inline code`\n/labels ~a\n`more inline code`"
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq([['reopen'], ['labels', '~a']])
      expect(msg).to eq "`some inline code`\n`more inline code`"
    end

    it 'does not get confused if command comes before a blockcode' do
      msg = "/reopen\n```\nsome blockcode\n```\n/labels ~a\n```\nmore blockcode\n```"
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq([['reopen'], ['labels', '~a']])
      expect(msg).to eq "```\nsome blockcode\n```\n```\nmore blockcode\n```"
    end

    it 'does not extract commands inside a blockcode' do
      msg = "Hello\r\n```\r\nThis is some text\r\n/close\r\n/assign @user\r\n```\r\n\r\nWorld"
      expected = msg.delete("\r")
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq expected
    end

    it 'does not extract commands inside a blockquote' do
      msg = "Hello\r\n>>>\r\nThis is some text\r\n/close\r\n/assign @user\r\n>>>\r\n\r\nWorld"
      expected = msg.delete("\r")
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq expected
    end

    it 'does not extract commands inside a HTML tag' do
      msg = "Hello\r\n<div>\r\nThis is some text\r\n/close\r\n/assign @user\r\n</div>\r\n\r\nWorld"
      expected = msg.delete("\r")
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq expected
    end

    it 'does not extract commands in multiline inline code on seperated rows' do
      msg = "Hello\r\n`\r\nThis is some text\r\n/close\r\n/assign @user\r\n`\r\n\r\nWorld"
      expected = msg.delete("\r")
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq expected
    end

    it 'does not extract commands in multiline inline code starting from text' do
      msg = "Hello `This is some text\r\n/close\r\n/assign @user\r\n`\r\n\r\nWorld"
      expected = msg.delete("\r")
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq expected
    end

    it 'does not extract commands in inline code' do
      msg = "`This is some text\r\n/close\r\n/assign @user\r\n`\r\n\r\nWorld"
      expected = msg.delete("\r")
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq expected
    end

    it 'limits to passed commands when they are passed' do
      msg = <<~MSG.strip
      Hello, we should only extract the commands passed
      /reopen
      /labels hello world
      /power
      MSG
      expected_msg = <<~EXPECTED.strip
      Hello, we should only extract the commands passed
      /power
      EXPECTED
      expected_commands = [['reopen'], ['labels', 'hello world']]

      msg, commands = extractor.extract_commands(msg, only: [:open, :labels])

      expect(commands).to eq(expected_commands)
      expect(msg).to eq expected_msg
    end

    it 'fails fast for strings with many newlines' do
      msg = '`' + "\n" * 100_000

      expect do
        Timeout.timeout(3.seconds) { extractor.extract_commands(msg) }
      end.not_to raise_error
    end
  end

  describe '#redact_commands' do
    using RSpec::Parameterized::TableSyntax

    where(:text, :expected) do
      "hello\n/labels ~label1 ~label2\nworld" | "hello\n`/labels ~label1 ~label2`\nworld"
      "hello\n/open\n/labels ~label1\nworld"  | "hello\n`/open`\n`/labels ~label1`\nworld"
      "hello\n/reopen\nworld"                 | "hello\n`/reopen`\nworld"
      "/reopen\nworld"                        | "`/reopen`\nworld"
      "hello\n/open"                          | "hello\n`/open`"
    end

    with_them do
      it 'encloses quick actions with code span markdown' do
        expect(extractor.redact_commands(text)).to eq(expected)
      end
    end
  end
end
