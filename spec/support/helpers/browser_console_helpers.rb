# frozen_string_literal: true

module BrowserConsoleHelpers
  # Define an error class for browser console messages
  BrowserConsoleError = Class.new(StandardError)

  # Filter out noisy browser console messages
  #
  # This is used when printing out the full console messages in failed tests
  BROWSER_CONSOLE_FILTER = Regexp.union(
    [
      '"[HMR] Waiting for update signal from WDS..."',
      '"[WDS] Hot Module Replacement enabled."',
      '"[WDS] Live Reloading enabled."',
      'Download the Vue Devtools extension',
      'Download the Apollo DevTools',
      "Unrecognized feature: 'interest-cohort'",
      'Does this page need fixes or improvements?',

      # Needed after https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60933
      # which opts out gitlab from FloC by default
      # see https://web.dev/floc/ for more info on FloC
      "Origin trial controlled feature not enabled: 'interest-cohort'",

      # ERR_CONNECTION error could happen due to automated test session disabling browser network request
      'net::ERR_CONNECTION'
    ]
  )

  # Filter out noisy browser console **error** messages
  #
  # This is used for expect_page_to_have_no_console_errors
  BROWSER_CONSOLE_ERROR_FILTER = Regexp.union(
    [
      /gravatar\.com.*Failed to load resource/,
      /snowplowanalytics.*Failed to load resource/
    ]
  )

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

  def raise_if_unexpected_browser_console_output
    console = browser_logs.reject { |log| log.message =~ BROWSER_CONSOLE_FILTER }

    return unless console.present?

    message = "Unexpected browser console output:\n#{console.map(&:message).join("\n")}"
    raise BrowserConsoleError, message
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
