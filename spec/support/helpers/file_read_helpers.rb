# frozen_string_literal: true

module FileReadHelpers
  def stub_file_read(file, content: nil, error: nil, exist: true)
    allow_or_expect_file_read(
      file, mode: :allow, content: content, error: error, exist: exist
    )
  end

  def expect_file_read(file, content: nil, error: nil, exist: true)
    allow_or_expect_file_read(
      file, mode: :expect, content: content, error: error, exist: exist
    )
  end

  def expect_file_not_to_read(file)
    allow_original_file_calls

    expect(File).not_to receive(:read).with(file)
  end

  private

  def allow_or_expect_file_read(file, mode:, content:, error:, exist:)
    allow_original_file_calls
    allow(File).to receive(:exist?).with(file).and_return(exist)

    expectation = if mode == :allow
                    allow(File).to receive(:read).with(file)
                  elsif mode == :expect
                    expect(File).to receive(:read).with(file)
                  else
                    raise ArgumentError, "expected :allow or :expect for `mode`, got `#{mode}`"
                  end

    if error
      expectation.and_raise(error)
    elsif content
      expectation.and_return(content)
    else
      expectation
    end
  end

  def allow_original_file_calls
    # Don't set this mock twice, otherwise subsequent calls will clobber
    # previous mocks
    return if @allow_original_file_calls

    @allow_original_file_calls = true
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:exist?).and_call_original
  end
end
