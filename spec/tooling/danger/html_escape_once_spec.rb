# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/html_escape_once'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::HtmlEscapeOnce, feature_category: :markdown do
  include_context "with dangerfile"

  subject(:html_escape_once) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:all_changed_files) { ['lib/banzai/filter/include_filter.rb'] }
  let(:changed_lines) { [] }

  before do
    allow(fake_helper).to receive_messages(all_changed_files: all_changed_files, changed_lines: changed_lines)
  end

  describe '#check_html_escape_once_calls' do
    subject(:check_html_escape_once_calls) { html_escape_once.check_html_escape_once_calls }

    context 'when there are no added calls' do
      let(:changed_lines) { ['+def some_method', '+ end'] }

      it 'does not fail' do
        expect(html_escape_once).not_to receive(:fail)
        check_html_escape_once_calls
      end
    end

    context 'when there is a changed call' do
      let(:changed_lines) { ['-ERB::Util.html_escape_once("hello")', '+ERB::Util.html_escape_once("hola")'] }

      it 'does not fail' do
        expect(html_escape_once).not_to receive(:fail)
        check_html_escape_once_calls
      end
    end

    context 'when there is a removed call' do
      let(:changed_lines) { ['-ERB::Util.html_escape_once("hello")'] }

      it 'does not fail' do
        expect(html_escape_once).not_to receive(:fail)
        check_html_escape_once_calls
      end
    end

    context 'when there is an added call' do
      let(:changed_lines) { ['+ERB::Util.html_escape_once("hello")'] }

      it 'fails' do
        expect(html_escape_once).to receive(:fail).with(
          %r{^Added calls found in:\n\n- `lib/banzai/filter/include_filter\.rb`\n})
        check_html_escape_once_calls
      end
    end

    context 'when there is a call added to a line with one already in it' do
      let(:changed_lines) do
        [
          '-ERB::Util.html_escape_once("hello")',
          '+ERB::Util.html_escape_once("hello") + escape_once("hi")'
        ]
      end

      it 'fails' do
        expect(html_escape_once).to receive(:fail).with(
          %r{^Added calls found in:\n\n- `lib/banzai/filter/include_filter\.rb`\n})
        check_html_escape_once_calls
      end
    end

    context 'when there is a call removed from a line that had two' do
      let(:changed_lines) do
        [
          '-ERB::Util.html_escape_once("hello") + escape_once("hi")',
          '+ERB::Util.html_escape_once("hello")'
        ]
      end

      it 'does not fail' do
        expect(html_escape_once).not_to receive(:fail)
        check_html_escape_once_calls
      end
    end

    context 'when there is an added call to something similar' do
      let(:changed_lines) { ['+not_actually_html_escape_once("hello")'] }

      it 'does not fail' do
        expect(html_escape_once).not_to receive(:fail)
        check_html_escape_once_calls
      end
    end

    context 'when unrelated or ignored files are changed' do
      let(:all_changed_files) { ['irrelevant.js', 'danger/ignored.rb'] }

      it 'does not check their contents' do
        expect(fake_helper).not_to receive(:changed_lines)
        check_html_escape_once_calls
      end
    end
  end
end
