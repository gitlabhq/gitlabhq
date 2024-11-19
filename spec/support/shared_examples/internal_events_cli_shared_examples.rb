# frozen_string_literal: true

# Asserts that files created by the Internal Events CLI are as expected after
# the CLI has been exited gracefully or a definition flow is completed.
#
# Expected structure of test_case: {
#   inputs: [Hash] # content provided to the CLI
#     keystrokes: [Array<String>] # keyboard interactions to simulate
#     files: [Array]
#     - path: [String] # location to create the file ahead of running the CLI
#       content: [String] # fixure file which contains the expected file contents
#   outputs: [Hash] # expected results of running the CLI
#     files: [Array]
#     - path: [String] # expected path for where the new file should be created
#       content: [String] # fixure file which contains the expected file contents
# }
#
# Note:
# To be used with shared context 'when running the Internal Events Cli'.
# See event_definer_examples.yml & metric_definer_examples.yml for examples.
RSpec.shared_examples 'creates the right definition files' do |description, test_case = {}|
  # For expected keystroke mapping, see https://github.com/piotrmurach/tty-reader/blob/master/lib/tty/reader/keys.rb
  let(:keystrokes) { test_case.dig('inputs', 'keystrokes') || [] }
  let(:input_files) { test_case.dig('inputs', 'files') || [] }
  let(:output_files) { test_case.dig('outputs', 'files') || [] }
  let(:timeout_error) { 'Internal Events CLI timed out while awaiting completion.' }

  # Script execution should stop without a reduced timeout
  let(:interaction_timeout) { example_timeout }

  it "in scenario: #{description}" do
    delete_old_ouputs # just in case
    prep_input_files
    queue_cli_inputs(keystrokes)
    expect_file_creation

    wait_for_cli_completion

    # Check that script exited gracefully as a result of user input
    expect(plain_last_lines(10)).to include('Thanks for using the Internal Events CLI!')
  end

  private

  def delete_old_ouputs
    [input_files, output_files].flatten.each do |file_info|
      FileUtils.rm_f(Rails.root.join(file_info['path']))
    end
  end

  def prep_input_files
    input_files.each do |file|
      File.write(
        Rails.root.join(file['path']),
        File.read(Rails.root.join(file['content']))
      )
    end
  end

  def expect_file_creation
    if output_files.any?
      output_files.each do |file|
        expect(File).to receive(:write).with(file['path'], File.read(file['content']))
      end
    else
      expect(File).not_to receive(:write)
    end
  end

  def wait_for_cli_completion
    with_cli_thread do |thread|
      wait_for(timeout_error) { !thread.alive? }
    end
  end
end
