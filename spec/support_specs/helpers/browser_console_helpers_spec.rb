# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../support/helpers/browser_console_helpers'

RSpec.describe BrowserConsoleHelpers, feature_category: :tooling do
  describe 'BROWSER_CONSOLE_ERROR_FILTER' do
    subject(:filter) { described_class::BROWSER_CONSOLE_ERROR_FILTER }

    where(:message) do
      [
        ['https://www.gravatar.com/avatar/xyz - Failed to load resource: net::ERR_SOCKET_NOT_CONNECTED'],
        ['https://sp.gitlab.com/snowplowanalytics.js - Failed to load resource: net::ERR_CONNECTION_REFUSED'],
        ['net::ERR_CONNECTION_REFUSED'],
        ['http://127.0.0.1:3000/assets/webpack/framework.bundle.js 47313:24 "[rspack-dev-server]" Event'],
        [
          "http://127.0.0.1:3000/assets/webpack/framework.bundle.js 46725 WebSocket connection to " \
            "'wss://gdk.test:3443/_hmr/' failed: Error in connection establishment: net::ERR_SOCKET_NOT_CONNECTED"
        ]
      ]
    end

    with_them do
      it 'matches the console message' do
        expect(message).to match(filter)
      end
    end

    context 'with unrelated messages' do
      where(:message) do
        [
          ['Some unrelated console message'],
          ['Uncaught TypeError: something is not a function']
        ]
      end

      with_them do
        it 'does not match the console message' do
          expect(message).not_to match(filter)
        end
      end
    end
  end

  describe '#raise_if_unexpected_browser_console_output' do
    let(:log_entry_class) { Struct.new(:level, :message) }
    let(:instance) { Object.new.extend(described_class) }

    subject(:call_method) { instance.raise_if_unexpected_browser_console_output }

    before do
      allow(instance).to receive(:browser_logs).and_return(browser_logs)
    end

    context 'when there is an unexpected SEVERE console message' do
      let(:browser_logs) { [log_entry_class.new('SEVERE', 'Uncaught TypeError: something is not a function')] }

      it 'raises BrowserConsoleError' do
        expect { call_method }.to raise_error(described_class::BrowserConsoleError, /Uncaught TypeError/)
      end
    end

    context 'when the console output should not raise' do
      where(:level, :message) do
        [
          ['WARNING', '[GlCollapsibleListbox] Toggle is missing a tabindex'],
          ['SEVERE', 'net::ERR_CONNECTION_REFUSED'],
          ['SEVERE', 'https://www.gravatar.com/avatar/xyz - Failed to load resource: net::ERR_SOCKET_NOT_CONNECTED']
        ]
      end

      with_them do
        let(:browser_logs) { [log_entry_class.new(level, message)] }

        it 'does not raise' do
          expect { call_method }.not_to raise_error
        end
      end
    end

    context 'when there are no console messages' do
      let(:browser_logs) { [] }

      it 'does not raise' do
        expect { call_method }.not_to raise_error
      end
    end

    context 'with an allowlist entry' do
      let(:browser_logs) do
        [log_entry_class.new('SEVERE', "Uncaught TypeError: Cannot read properties of null (reading 'text')")]
      end

      let(:example) do
        instance_double(RSpec::Core::Example, metadata: {
          rerun_file_path: './spec/features/issues/notes_spec.rb',
          file_path: './spec/support/shared_examples/notes.rb'
        })
      end

      subject(:call_method) { instance.raise_if_unexpected_browser_console_output(example) }

      before do
        allow(described_class).to receive(:browser_console_allowlist).and_return([
          { 'message' => "Uncaught TypeError: Cannot read properties of null (reading 'text')", 'specs' => specs }
        ])
      end

      context 'when the entry lists the spec file the example reruns from' do
        let(:specs) { ['spec/features/issues/notes_spec.rb'] }

        it 'does not raise' do
          expect { call_method }.not_to raise_error
        end
      end

      context 'when the entry lists only the shared examples file' do
        let(:specs) { ['spec/support/shared_examples/notes.rb'] }

        it 'raises, because scoping uses rerun_file_path' do
          expect { call_method }.to raise_error(described_class::BrowserConsoleError, /reading 'text'/)
        end

        it 'tells how to allow the error and links to the docs' do
          expect { call_method }.to raise_error(described_class::BrowserConsoleError) { |error|
            expect(error.message).to include(
              'Unexpected browser console errors in spec/features/issues/notes_spec.rb:',
              'add an entry for spec/features/issues/notes_spec.rb',
              'spec/support/browser_console_allowlist.yml',
              described_class::BROWSER_CONSOLE_DOCS_URL
            )
          }
        end
      end
    end

    context 'with an allowlist entry that lists several messages' do
      let(:location) { 'http://127.0.0.1:3000/assets/webpack/main.chunk.js 1204:19' }
      let(:graphql_message) { "#{location} \"GraphQL execution errors for query 'runners'\"" }
      let(:example) do
        instance_double(RSpec::Core::Example,
          metadata: { rerun_file_path: './spec/features/projects/ci/editor_spec.rb' })
      end

      subject(:call_method) { instance.raise_if_unexpected_browser_console_output(example) }

      before do
        allow(described_class).to receive(:browser_console_allowlist).and_return([
          {
            'messages' => ["GraphQL execution errors for query 'runners'", 'Object'],
            'specs' => ['spec/features/projects/ci/editor_spec.rb']
          }
        ])
      end

      context 'when the messages match the list in order' do
        let(:browser_logs) do
          [log_entry_class.new('SEVERE', graphql_message), log_entry_class.new('SEVERE', "#{location} Object")]
        end

        it 'does not raise' do
          expect { call_method }.not_to raise_error
        end
      end

      context 'when a message follows the matched group' do
        let(:browser_logs) do
          [
            log_entry_class.new('SEVERE', graphql_message),
            log_entry_class.new('SEVERE', "#{location} Object"),
            log_entry_class.new('SEVERE', "#{location} Object")
          ]
        end

        it 'raises for that message only' do
          expect { call_method }.to raise_error(described_class::BrowserConsoleError) { |error|
            expect(error.message).to include("  #{location} Object\n")
            expect(error.message).not_to include('runners')
          }
        end
      end

      context 'when only a later line is logged' do
        let(:browser_logs) { [log_entry_class.new('SEVERE', "#{location} Object")] }

        it 'raises' do
          expect { call_method }.to raise_error(described_class::BrowserConsoleError, /Object/)
        end
      end
    end
  end

  describe '.allowed_console_message?' do
    let(:spec_path) { 'ee/spec/features/boards/sidebar_spec.rb' }
    let(:message) { 'http://127.0.0.1:3000/assets/webpack/main.chunk.js 12:34 Uncaught RangeError: Invalid time value' }
    let(:entry) do
      { 'message' => 'RangeError: Invalid time value', 'specs' => ['ee/spec/features/boards/*_spec.rb'] }
    end

    subject { described_class.allowed_console_message?(message, spec_path) }

    before do
      allow(described_class).to receive(:browser_console_allowlist).and_return([entry])
    end

    it { is_expected.to be(true) }

    context 'when the message does not contain the entry text' do
      let(:message) { 'Uncaught TypeError: something is not a function' }

      it { is_expected.to be(false) }
    end

    context 'when a Vue error handler wraps the error and Chrome escapes the quotes' do
      let(:message) do
        'main.chunk.js 1:1 "[Vue warn]: Error in render: \"RangeError: Invalid time value\"\n\nfound in"'
      end

      it { is_expected.to be(true) }
    end

    context 'when the entry is written with the quotes Chrome adds' do
      let(:entry) { super().merge('message' => '"RangeError: Invalid time value"') }

      it { is_expected.to be(true) }
    end

    context 'when the message has no text' do
      let(:message) { 'http://127.0.0.1:3000/assets/webpack/main.chunk.js 12:34' }

      it { is_expected.to be(false) }

      context 'and the entry message is empty' do
        let(:entry) { super().merge('message' => '') }

        it { is_expected.to be(true) }

        it 'does not allow a message with text' do
          other = 'main.chunk.js 1:1 Uncaught Error: boom'

          expect(described_class.allowed_console_message?(other, spec_path)).to be(false)
        end
      end
    end

    context 'when the spec file is outside the entry globs' do
      let(:spec_path) { 'spec/features/boards/sidebar_spec.rb' }

      it { is_expected.to be(false) }
    end

    context 'when a glob would match across directories only without FNM_PATHNAME' do
      let(:spec_path) { 'ee/spec/features/boards/nested/sidebar_spec.rb' }

      it { is_expected.to be(false) }
    end
  end
end
