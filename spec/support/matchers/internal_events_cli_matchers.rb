# frozen_string_literal: true

module InternalEventsCliMatchHelpers
  def supports_block_expectations?
    true
  end

  def supports_value_expectations?
    false
  end

  def condition_eventually_met?(&blk)
    wait_for(description, &blk)

    true
  rescue StandardError => e
    return false if e.message.include?(description)

    raise
  end

  def format_error_output(string)
    string.lines
      .map { |line| "\e[0;37m#{line}\e[0m" } # wrap in white
      .join('')
      .gsub("\e[1G", "\e[1G       ") # align to error indent
  end

  # Truncated outputs may include more line deletions than
  # already printed lines, so we don't want to overwrite previous lines
  def format_buffer(string)
    line_deletion_counts = string.lines.map { |line| line.scan("\e[1A").length }

    buffer_length = line_deletion_counts.each.with_index.reduce(0) do |buffer, (deleted_lines, idx)|
      excess_lines = idx + buffer - deleted_lines
      excess_lines < 0 ? buffer + excess_lines.abs : buffer
    end

    "\n" * buffer_length
  end
end

RSpec::Matchers.define :eventually_equal_cli_text do |expected_value|
  include InternalEventsCliMatchHelpers

  diffable

  description { 'Internal Events CLI output equals expected value' }

  match do |proc|
    condition_eventually_met? do
      @expected = expected_value
      @actual = proc.call

      @actual == @expected
    end
  end

  failure_message do
    <<~TEXT
    EXPECTED OUTPUT:
    #{format_error_output(@expected)}

    GOT OUTPUT:
    #{format_buffer(@actual)}#{format_error_output(@actual)}

    TEXT
  end
end

RSpec::Matchers.define :eventually_include_cli_text do |*expected_strings|
  include InternalEventsCliMatchHelpers

  description { 'Internal Events CLI output includes expected strings' }

  match do |proc|
    condition_eventually_met? do
      output = proc.call

      expected_strings.all? { |string| output.include?(string) }
    end
  end

  failure_message do |proc|
    output = proc.call

    <<~TEXT
    #{
      expected_strings
        .map.with_index { |string, idx| status_for(output, string, idx) }
        .join("\n\n")
    }

    GOT OUTPUT:
    #{format_buffer(output)}#{format_error_output(output)}


    TEXT
  end

  def status_for(output, string, idx)
    if output.include?(string)
      "\e[0;32mEXPECTED TEXT ##{idx} -- SUCCESS:\e[0m\n#{format_error_output(string)}"
    else
      "\e[0;31mEXPECTED TEXT ##{idx} -- FAILURE:\e[0m\n#{format_error_output(string)}"
    end
  end
end
