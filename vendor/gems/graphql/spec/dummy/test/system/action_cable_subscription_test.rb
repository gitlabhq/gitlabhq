# frozen_string_literal: true
require "application_system_test_case"

class ActionCableSubscriptionsTest < ApplicationSystemTestCase
  setup do
    ActionCable.server.config.logger = Logger.new(STDOUT)
  end
  # This test covers a lot of ground!
  test "it handles subscriptions" do
    # Load the page and let the subscriptions happen
    visit "/"
    # make sure they connect successfully
    assert_selector "#updates-1-connected"
    assert_selector "#updates-2-connected"

    # Trigger a few updates, make sure we get a client update:
    click_on("Trigger 1")
    click_on("Trigger 1")
    click_on("Trigger 1")
    assert_selector "#updates-1-3", text: "3"
    # Make sure there aren't any unexpected elements:
    refute_selector "#updates-1-4"
    refute_selector "#updates-2-1"

    # Now, trigger updates to a different stream
    # and make sure the previous stream is not affected
    click_on("Trigger 2")
    click_on("Trigger 2")
    assert_selector "#updates-2-1", text: "1"
    assert_selector "#updates-2-2", text: "2"
    refute_selector "#updates-2-3"
    refute_selector "#updates-1-4"

    # Now unsubscribe one, it should not receive updates but the other should
    click_on("Unsubscribe 1")
    click_on("Trigger 1")
    # This should not have changed
    refute_selector "#updates-1-4"

    click_on("Trigger 2")
    assert_selector "#updates-2-3", text: "3"
    refute_selector "#updates-1-4"

    # wacky behavior to make sure the custom serializer is used:
    click_on("Trigger 2")
    assert_selector "#updates-2-400", text: "400"
  end

  # Wrap an `assert_selector` call in a debugging check
  def debug_assert_selector(selector)
    if !page.has_css?(selector)
      puts "[debug_assert_selector(#{selector.inspect})] Failed to find #{selector.inspect} in:"
      puts page.html
    else
      puts "[debug_assert_selector(#{selector.inspect})] Found #{selector.inspect}"
    end
    assert_selector(selector)
  end

  # It seems like ActionCable's order of evaluation here is non-deterministic,
  # so detect which order to make the assertions.
  # (They still both have to pass, but we don't know exactly what order the evaluations went in.)
  def detect_update_values(possibility_1, possibility_2)
    if page.has_css?("#fingerprint-updates-1-update-1-value-#{possibility_1}")
      [possibility_1, possibility_2]
    else
      [possibility_2, possibility_1]
    end
  end


  test "it only re-runs queries once for subscriptions with matching fingerprints" do
    GraphqlChannel::CounterIncremented.reset_call_count
    visit "/"
    using_wait_time 10 do
      sleep 1
      # Make 3 subscriptions to the same payload
      click_on("Subscribe with fingerprint 1")

      debug_assert_selector "#fingerprint-updates-1-connected-1"

      click_on("Subscribe with fingerprint 1")
      debug_assert_selector "#fingerprint-updates-1-connected-2"
      click_on("Subscribe with fingerprint 1")
      debug_assert_selector "#fingerprint-updates-1-connected-3"

      # And two to the next payload
      click_on("Subscribe with fingerprint 2")
      debug_assert_selector "#fingerprint-updates-2-connected-1"
      click_on("Subscribe with fingerprint 2")
      debug_assert_selector "#fingerprint-updates-2-connected-2"

      # Now trigger. We expect a total of two updates:
      # - One is built & delivered to the first three subscribers
      # - Another is built & delivered to the next two
      click_on("Trigger with fingerprint 2")

      # The order here is random, I think depending on ActionCable's internal storage:
      fingerprint_1_value, fingerprint_2_value = detect_update_values(1, 2)

      # These all share the first value:
      debug_assert_selector "#fingerprint-updates-1-update-1-value-#{fingerprint_1_value}"
      debug_assert_selector "#fingerprint-updates-1-update-2-value-#{fingerprint_1_value}"
      debug_assert_selector "#fingerprint-updates-1-update-3-value-#{fingerprint_1_value}"
      # and these share the second value:
      debug_assert_selector "#fingerprint-updates-2-update-1-value-#{fingerprint_2_value}"
      debug_assert_selector "#fingerprint-updates-2-update-2-value-#{fingerprint_2_value}"

      click_on("Unsubscribe with fingerprint 2")
      click_on("Trigger with fingerprint 1")

      fingerprint_1_value_2, fingerprint_2_value_2 = detect_update_values(3, 4)

      # These get an update
      debug_assert_selector "#fingerprint-updates-1-update-1-value-#{fingerprint_1_value_2}"
      debug_assert_selector "#fingerprint-updates-1-update-2-value-#{fingerprint_1_value_2}"
      debug_assert_selector "#fingerprint-updates-1-update-3-value-#{fingerprint_1_value_2}"
      # But these are unsubscribed:
      refute_selector "#fingerprint-updates-2-update-1-value-#{fingerprint_2_value_2}"
      refute_selector "#fingerprint-updates-2-update-2-value-#{fingerprint_2_value_2}"
      click_on("Unsubscribe with fingerprint 1")
      # Make a new subscription and make sure it's updated:
      click_on("Subscribe with fingerprint 2")
      click_on("Trigger with fingerprint 2")
      debug_assert_selector "#fingerprint-updates-2-update-1-value-#{fingerprint_2_value_2}"
      # But this one was unsubscribed:
      refute_selector "#fingerprint-updates-1-update-1-value-#{fingerprint_1_value_2 + 1}"
      refute_selector "#fingerprint-updates-1-update-1-value-#{fingerprint_1_value_2 + 2}"
    end
  end

  test "it unsubscribes from the server" do
    GraphqlChannel::CounterIncremented.reset_call_count
    visit "/"
    using_wait_time 10 do
      sleep 1
      # Establish the connection
      click_on("Subscribe with fingerprint 1")
      debug_assert_selector "#fingerprint-updates-1-connected-1"
      # Trigger once
      click_on("Trigger with fingerprint 1")
      debug_assert_selector "#fingerprint-updates-1-update-1-value-1"

      # Server unsubscribe
      click_on("Server-side unsubscribe with fingerprint 1")
      # Subsequent updates should fail
      click_on("Trigger with fingerprint 1")
      refute_selector "#fingerprint-updates-1-update-2-value-2"

      # The client has only 2 connections (from the initial 2)
      assert_text "Remaining ActionCable subscriptions: 2"
    end
  end

  test "it unsubscribes with a message" do
    GraphqlChannel::CounterIncremented.reset_call_count
    visit "/"
    using_wait_time 10 do
      sleep 1
      # Establish the connection
      click_on("Subscribe with fingerprint 1")
      debug_assert_selector "#fingerprint-updates-1-connected-1"
      # Trigger once
      click_on("Trigger with fingerprint 1")
      debug_assert_selector "#fingerprint-updates-1-update-1-value-1"

      # Server unsubscribe
      click_on("Unsubscribe with message with fingerprint 1")
      # Magic value from unsubscribe hook:
      debug_assert_selector "#fingerprint-updates-1-update-1-value-9999"
      # The client has only 2 connections (from the initial 2)
      assert_text "Remaining ActionCable subscriptions: 2"
    end
  end
end
