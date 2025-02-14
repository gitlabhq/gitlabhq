# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../../rubocop/cop/gitlab/documentation_links/link'

RSpec.describe RuboCop::Cop::Gitlab::DocumentationLinks::Link, feature_category: :navigation do
  using RSpec::Parameterized::TableSyntax

  shared_examples 'no offenses registered' do
    it 'does not register any offenses' do
      expect_no_offenses(code)
    end
  end

  shared_examples 'offense registered' do |offense_message|
    it 'registers an offense' do
      expect_offense(<<~'RUBY', code: code, offense_message: offense_message)
             %{code}
             ^{code} %{offense_message}
      RUBY
    end
  end

  context 'when no argument is passed' do
    let(:code) { "help_page_path" }

    it_behaves_like 'no offenses registered'
  end

  context 'when the path is valid' do
    before do
      allow(File).to receive(:exist?).with('doc/this/file/exists.md').and_return(true)
    end

    where(:code) do
      [
        "help_page_path('/this/file/exists.md')",
        "help_page_url('/this/file/exists.md')"
      ]
    end

    with_them do
      it_behaves_like 'no offenses registered'
    end

    describe 'anchors' do
      before do
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with('doc/this/file/exists.md').and_return(<<~MARKDOWN)
          # Primary heading

          Intro

          ## This anchor exists

          Content

          ## This anchor exists

          More content

          ## This one has a custom ID {#my-custom-id}
        MARKDOWN
      end

      context 'when the anchor is valid' do
        where(:code) do
          [
            "help_page_path('/this/file/exists.md#primary-heading')",
            "help_page_path('/this/file/exists.md#this-anchor-exists')",
            "help_page_path('/this/file/exists.md#this-anchor-exists-1')",
            "help_page_path('/this/file/exists.md', anchor: 'this-anchor-exists')",
            "help_page_path('/this/file/exists.md', anchor: 'this-anchor-exists-1')",
            "help_page_path('/this/file/exists.md', anchor: 'my-custom-id')",
            "help_page_url('/this/file/exists.md#primary-heading')"
          ]
        end

        with_them do
          it_behaves_like 'no offenses registered'
        end
      end

      context 'when the anchor is invalid' do
        offense_message = "The anchor `#this-anchor-does-not-exist` was not found in [...]"

        context 'when the anchor is passed via the first argument' do
          let(:argument) { "'/this/file/exists.md#this-anchor-does-not-exist'" }

          it 'registers an offense with help_page_path' do
            expect_offense(<<~'RUBY', start: "help_page_path(", argument: argument, offense_message: offense_message)
              %{start}%{argument})
              _{start}^{argument} %{offense_message}
            RUBY
          end

          it 'registers an offense with help_page_url' do
            expect_offense(<<~'RUBY', start: "help_page_url(", argument: argument, offense_message: offense_message)
              %{start}%{argument})
              _{start}^{argument} %{offense_message}
            RUBY
          end
        end

        context 'when the anchor is passed via the anchor argument' do
          let(:start) { "help_page_path('/this/file/exists.md#this-anchor-does-not-exist', anchor: " }
          let(:argument) { "'this-anchor-does-not-exist'" }

          it 'registers an offense with help_page_path' do
            expect_offense(<<~'RUBY', start: start, argument: argument, offense_message: offense_message)
              %{start}%{argument})
              _{start}^{argument} %{offense_message}
            RUBY
          end
        end
      end

      context 'when the anchor is not a string' do
        let(:start) { "help_page_path('/this/file/exists.md', anchor: " }

        it 'registers an offense' do
          expect_offense(<<~'RUBY', start: start, argument: "anchor_variable")
            %{start}%{argument})
            _{start}^{argument} `help_page_path`'s `anchor` argument must be passed as a string [...]
          RUBY
        end
      end
    end
  end

  context 'when the path is invalid' do
    before do
      allow(File).to receive(:exists).and_return(false)
    end

    where(:start, :argument, :closure) do
      "help_page_path(" | "'/this/file/does/not/exist.md'" | ")"
      "help_page_path(" | "'/this/file/does/not/exist.md#some-anchor'" | ")"
      "help_page_path(" | "'/this/file/does/not/exist.md'" | ", anchor: 'some-anchor')"
      "help_page_url(" | "'/this/file/does/not/exist.md'" | ")"
    end

    with_them do
      it 'registers an offense' do
        expect_offense(<<~'RUBY', start: start, argument: argument, closure: closure)
          %{start}%{argument}%{closure}
          _{start}^{argument} This file does not exist: [...]
        RUBY
      end
    end

    context 'when the path is not a string' do
      let(:code) { "help_page_path(path_variable)" }

      it_behaves_like 'offense registered', "`help_page_path`'s first argument must be passed as a string [...]"
    end

    context 'when the path does not include the .md file extension' do
      where(:path, :correction) do
        '/this/path/lacks/md/extension'             | '/this/path/lacks/md/extension.md'
        '/this/path/lacks/md/extension.html'        | '/this/path/lacks/md/extension.md'
        '/this/path/lacks/md/extension#anchor'      | '/this/path/lacks/md/extension.md#anchor'
        '/this/path/lacks/md/extension.html#anchor' | '/this/path/lacks/md/extension.md#anchor'
      end

      with_them do
        it 'registers two offenses and corrects the missing extension' do
          expect_offense(<<~'RUBY', start: "help_page_path(", argument: "'#{path}'")
            %{start}%{argument})
            _{start}^{argument} This file does not exist: [...]
            ^{start}^{argument}^ Add .md extension to the link: [...]
          RUBY

          expect_correction("help_page_path('#{correction}')\n")
        end
      end
    end
  end

  describe '#external_dependency_checksum' do
    it 'returns a SHA256 digest used by RuboCop to invalid cache' do
      expect(cop.external_dependency_checksum).to match(/^\h{128}$/)
    end
  end
end
