# frozen_string_literal: true

module BrowserConsoleHelpers
  # Define an error class for browser console messages
  BrowserConsoleError = Class.new(StandardError)

  BROWSER_CONSOLE_DOCS_URL = "https://docs.gitlab.com/development/testing_guide/frontend_testing/#browser-console-errors-in-feature-specs"

  # Filter out noisy browser console **error** messages
  #
  # This is used for both expect_page_to_have_no_console_errors and
  # raise_if_unexpected_browser_console_output, which only ever consider SEVERE-level output.
  BROWSER_CONSOLE_ERROR_FILTER = Regexp.union(
    [
      # Chrome logs every failed request as SEVERE; many specs assert on 4xx/5xx responses on purpose.
      /Failed to load resource/,
      # The test environment has no network and a strict CSP, so third-party scripts, trackers and
      # media never load.
      /violates the following Content Security Policy directive/,
      /Refused to connect because it violates the document's Content Security Policy/,
      /snowplowanalytics\.js/,
      /ArkoseLabs initialization error/,
      /googletagmanager\.com/,
      # The Sentry stub forwards captureException calls to console.error.
      /\[Sentry stub\]/,
      # The test server does not serve a web manifest, and the GraphQL explorer embeds its fonts.
      %r{/-/manifest\.json.*Manifest:|Manifest fetch from .*/-/manifest\.json failed},
      /Loading the font 'data:font/,
      # The user counts request fails with 401 after the session ends.
      %r{Error retrieving user counts|/user_counts},
      # Headless Chrome skips view transitions and beforeunload prompts.
      /DOMException: Transition was skipped/,
      /Blocked attempt to show a 'beforeunload' confirmation panel/,
      # ActionCable is not always up when a page connects.
      /WebSocket connection to '.*cable' failed/,
      # Local runs only: the rspack dev server client cannot reach the GDK host for hot reload.
      /\[rspack-dev-server\]/,
      %r{WebSocket connection to '.*/_hmr/' failed},

      # ERR_CONNECTION error could happen due to automated test session disabling browser network request
      'net::ERR_CONNECTION'
    ]
  )

  # Known application errors that feature specs may still log, scoped to the spec files that log
  # them. Each entry needs a `message` and the `specs` it applies to. Remove an entry when the
  # error is fixed.
  BROWSER_CONSOLE_ALLOWLIST_PATH = File.expand_path('../browser_console_allowlist.yml', __dir__)

  # Chrome prefixes every message with its source URL and `line:column`.
  CONSOLE_MESSAGE_LOCATION = /\A\S+ \d+:\d+ ?/

  def self.browser_console_allowlist
    @browser_console_allowlist ||= YAML.safe_load_file(BROWSER_CONSOLE_ALLOWLIST_PATH)
  end

  # The message text without its location prefix, quotes and backslashes, so that an entry can be
  # written as plain text. Chrome quotes string arguments and escapes the quotes inside them.
  def self.normalize_console_message(message)
    message.sub(CONSOLE_MESSAGE_LOCATION, '').delete('"\\').strip
  end

  # An entry matches when its text occurs in the message. An empty entry matches only a message
  # with no text, which Chrome logs for an error object without a message.
  def self.console_message_matches?(text, entry_text)
    return text.empty? if entry_text.empty?

    text.include?(entry_text)
  end

  def self.allowed_console_message?(message, spec_path)
    unexpected_console_messages([message], spec_path).empty?
  end

  # The messages that no entry covers. A `messages` entry matches one console message per item, in order, so one
  # entry can cover a group of messages logged together, such as a text followed by `Object`.
  def self.unexpected_console_messages(messages, spec_path)
    texts = messages.map { |message| normalize_console_message(message) }
    entries = allowlist_entry_lines(spec_path)

    unexpected = []
    index = 0
    while index < texts.size
      covered = entries.filter_map { |lines| lines.size if console_lines_match?(texts.drop(index), lines) }.max

      unexpected << messages[index] unless covered
      index += covered || 1
    end

    unexpected
  end

  def self.allowlist_entry_lines(spec_path)
    browser_console_allowlist.filter_map do |entry|
      next unless entry['specs'].any? { |glob| File.fnmatch?(glob, spec_path, File::FNM_PATHNAME | File::FNM_EXTGLOB) }

      lines = Array(entry['messages'] || entry.fetch('message')).map { |line| normalize_console_message(line) }
      lines.presence || ['']
    end
  end

  def self.console_lines_match?(texts, lines)
    texts.size >= lines.size && lines.zip(texts).all? { |line, text| console_message_matches?(text, line) }
  end

  def browser_logs
    @browser_logs ||= []

    # note: In chromium, browser logs are *cleared* after fetching them. For us to create the expected behavior of
    #       returning the *full* set of logs each time this method is called, we need to keep track of a cache of
    #       @browser_logs and append the new logs to it.
    #       See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162499#note_2060667250 for more info.
    #
    # note: Firefox does not have #logs method, so we need to `try` and check if it's nil
    new_browser_logs = page.driver.browser.try(:logs)&.get(:browser)

    return @browser_logs if !new_browser_logs || new_browser_logs.empty?

    # why: We check for timestamps to determine if the driver is giving us a new set of logs or the same set of logs on
    #      each call. If it's a new set of logs, we need to append to cache.
    if @browser_logs.empty? || @browser_logs.first.timestamp == new_browser_logs.first.timestamp
      @browser_logs = new_browser_logs
    else
      @browser_logs += new_browser_logs
    end

    @browser_logs
  end

  def clear_browser_logs
    @browser_logs = []

    # why: We need to clear browser logs from Chromium, otherwise logs will spill over into other examples.
    #      Chromium has a built-in behavior that clears it's logs when requested.
    #      See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162499#note_2060667250 for more info.
    page.driver.browser.try(:logs)&.get(:browser)
  end

  def raise_if_unexpected_browser_console_output(example = nil)
    # rerun_file_path is the spec file itself; file_path points into shared_examples for shared groups.
    spec_path = example&.metadata&.dig(:rerun_file_path).to_s.delete_prefix('./')

    messages = browser_logs
      .select { |log| log.level == 'SEVERE' && log.message !~ BROWSER_CONSOLE_ERROR_FILTER }
      .map(&:message)
    unexpected = BrowserConsoleHelpers.unexpected_console_messages(messages, spec_path)

    return unless unexpected.present?

    raise BrowserConsoleError, unexpected_browser_console_message(unexpected, spec_path)
  end

  def unexpected_browser_console_message(messages, spec_path)
    location = spec_path.present? ? " in #{spec_path}" : ''
    entry = spec_path.present? ? "an entry for #{spec_path}" : 'an entry'

    <<~MESSAGE
      Unexpected browser console errors#{location}:

      #{messages.map { |message| "  #{message}" }.join("\n")}

      Feature specs fail when the browser console logs an error that is not in the allowlist.
      The error can come from the page under test, even when the spec's own assertions pass.

      Fix the error. If you cannot fix it in this merge request, add #{entry}
      to spec/support/browser_console_allowlist.yml.

      See #{BROWSER_CONSOLE_DOCS_URL}
    MESSAGE
  end

  def expect_page_to_have_no_console_errors(allow: nil)
    message_regex = if allow
                      Regexp.union([BROWSER_CONSOLE_ERROR_FILTER] + allow)
                    else
                      BROWSER_CONSOLE_ERROR_FILTER
                    end

    console = browser_logs.select { |log| log.level == 'SEVERE' && log.message !~ message_regex }

    expect(console).to be_empty, "Unexpected browser console errors:\n#{console.map(&:message).join("\n")}"
  end
end
