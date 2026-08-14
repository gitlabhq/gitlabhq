# frozen_string_literal: true

require 'selenium-webdriver'

# Chrome raises `Selenium::WebDriver::Error::UnknownError` with
#
#   unhandled inspector error: {"code":-32000,"message":"Node with given id does not belong to the document"}
#
# when a node resolved from the outgoing document is read after a navigation has replaced that
# document -- a visibility or text check immediately after a click that navigates, for example. It is
# a stale node by another name, and Chrome reports the same situation as a
# `StaleElementReferenceError` most of the time.
#
# Capybara only retries the error classes listed in `Capybara::Selenium::Driver#invalid_element_errors`,
# and `UnknownError` is not one of them, so the example fails outright. Adding it to that list is not
# an option either: `Capybara::Node::Base#catch_error?` matches on error class alone, so every
# unrelated `UnknownError` -- "session deleted because of page crash", say -- would be retried for the
# full wait time before surfacing.
#
# Translating this one message into the error Chrome should have raised lets Capybara's existing
# retry-and-reload machinery handle it, bounded by each query's wait time, and leaves every other
# `UnknownError` failing on the first attempt.
#
# `#execute` carries the whole W3C command set, so translating there covers element reads, text
# reads, script evaluation and actions -- clicks and key presses included -- in one place.
#
# The end-to-end suite needs the same fix but cannot share this one, as it loads a separate bundle
# that does not require spec/support. It lives in `QA::Page::Base#retry_on_swapped_document`.
#
# See https://gitlab.com/gitlab-org/gitlab/-/issues/594514
unless ::Selenium::WebDriver::Remote::Bridge.private_method_defined?(:execute) ||
    ::Selenium::WebDriver::Remote::Bridge.method_defined?(:execute)
  raise 'Selenium::WebDriver::Remote::Bridge#execute no longer exists. Swapped-document errors are ' \
    'no longer being translated, so navigation races will fail specs again. ' \
    'See spec/support/capybara_swapped_document.rb'
end

module Selenium
  module WebDriver
    module Remote
      class Bridge
        module TranslateSwappedDocumentError
          SWAPPED_DOCUMENT_MESSAGE = 'Node with given id does not belong to the document'

          private

          def execute(...)
            super
          rescue ::Selenium::WebDriver::Error::UnknownError => e
            raise unless e.message.include?(SWAPPED_DOCUMENT_MESSAGE)

            # Raising inside the rescue keeps the original error as the cause
            raise ::Selenium::WebDriver::Error::StaleElementReferenceError, e.message
          end
        end

        prepend TranslateSwappedDocumentError
      end
    end
  end
end
