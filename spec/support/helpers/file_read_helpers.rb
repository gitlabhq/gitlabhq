# frozen_string_literal: true

module FileReadHelpers
  def stub_file_read(file, content: nil, error: nil)
    allow_original_file_read

    expectation = allow(File).to receive(:read).with(file)

    if error
      expectation.and_raise(error)
    elsif content
      expectation.and_return(content)
    else
      expectation
    end
  end

  def expect_file_read(file, content: nil, error: nil)
    allow_original_file_read

    expectation = expect(File).to receive(:read).with(file)

    if error
      expectation.and_raise(error)
    elsif content
      expectation.and_return(content)
    else
      expectation
    end
  end

  def expect_file_not_to_read(file)
    allow_original_file_read

    expect(File).not_to receive(:read).with(file)
  end

  private

  def allow_original_file_read
    # Don't set this mock twice, otherwise subsequent calls will clobber
    # previous mocks
    return if @allow_original_file_read

    @allow_original_file_read = true
    allow(File).to receive(:read).and_call_original
  end
end
