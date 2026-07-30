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
        ['net::ERR_CONNECTION_REFUSED']
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
  end
end
