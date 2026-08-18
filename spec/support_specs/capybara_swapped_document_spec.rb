# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'
require 'capybara/selenium/driver'
require 'selenium-webdriver'
require 'support/capybara_swapped_document'

RSpec.describe Selenium::WebDriver::Remote::Bridge::TranslateSwappedDocumentError, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- support_specs is the conventional location for specs testing spec/support files
  let(:bridge) do
    Class.new do
      attr_reader :calls

      def initialize(error)
        @error = error
        @calls = 0
      end

      def execute(command, opts = {}, command_hash = nil)
        @calls += 1
        raise @error if @error

        [command, opts, command_hash]
      end

      prepend Selenium::WebDriver::Remote::Bridge::TranslateSwappedDocumentError
    end.new(error)
  end

  let(:swapped_document_error) do
    Selenium::WebDriver::Error::UnknownError.new(
      'unknown error: unhandled inspector error: {"code":-32000,' \
        '"message":"Node with given id does not belong to the document"}'
    )
  end

  it 'is prepended to the real bridge, not only to the stub used below' do
    expect(Selenium::WebDriver::Remote::Bridge.ancestors).to include(described_class)
  end

  it 'translates the error when raised through the real Bridge#execute' do
    real_bridge = Selenium::WebDriver::Remote::Bridge.new(url: 'http://localhost:4444')
    http = instance_double(Selenium::WebDriver::Remote::Http::Default)

    allow(real_bridge).to receive_messages(session_id: 'a-session', http: http)
    allow(http).to receive(:call).and_raise(swapped_document_error)

    expect { real_bridge.send(:execute, :get_element_text, id: 'an-element') }
      .to raise_error(Selenium::WebDriver::Error::StaleElementReferenceError)
  end

  context 'when Chrome reports that the document was swapped' do
    let(:error) { swapped_document_error }

    it 'translates it into an error Capybara retries' do
      expect { bridge.send(:execute, :get_element_text) }.to raise_error(
        Selenium::WebDriver::Error::StaleElementReferenceError,
        include(described_class::SWAPPED_DOCUMENT_MESSAGE)
      )
    end

    it 'keeps the original error as the cause' do
      bridge.send(:execute, :get_element_text)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
      expect(e.cause).to be(swapped_document_error)
    end

    it 'is retriable by Capybara, unlike the error Chrome raised', :aggregate_failures do
      invalid_element_errors = Capybara::Selenium::Driver.new(nil).invalid_element_errors

      expect(invalid_element_errors).to include(Selenium::WebDriver::Error::StaleElementReferenceError)
      expect(invalid_element_errors).not_to include(Selenium::WebDriver::Error::UnknownError)
    end
  end

  context 'when an UnknownError is raised for any other reason' do
    let(:error) do
      Selenium::WebDriver::Error::UnknownError.new('unknown error: session deleted because of page crash')
    end

    it 'passes it through untranslated' do
      expect { bridge.send(:execute, :get_element_text) }
        .to raise_error(Selenium::WebDriver::Error::UnknownError, /page crash/)
    end
  end

  context 'when the command succeeds' do
    let(:error) { nil }

    it 'returns the result and calls through exactly once', :aggregate_failures do
      expect(bridge.send(:execute, :get_element_text, { id: 'abc' })).to eq([:get_element_text, { id: 'abc' }, nil])
      expect(bridge.calls).to eq(1)
    end
  end
end
