# frozen_string_literal: true

# Sets up the stubs and cleanup helpers for running the Internal Events CLI
# Must `require 'tty/prompt/test'` and require_relative `../scripts/internal_events/cli`
#
# Debugging tips:
# 1. Add `puts prompt.output.string` before `thread.exit` to see the full output from the test run
# 2. Include a `binding.pry` at the start of #queue_cli_inputs to pause execution & run the script manually
#       -> because these tests add/remove fixtures from the actual definition directories,
#          the CLI can run with the exact same initial state in another window
#
RSpec.shared_context 'when running the Internal Events Cli' do
  include InternalEventsCliHelpers
  include WaitHelpers

  let(:entrypoint_class) { Cli }
  let(:prompt) { GitlabPrompt.new(TTY::Prompt::Test.new) }
  let(:files_to_cleanup) { [] }

  before do
    stub_milestone('16.6')
    collect_file_writes(files_to_cleanup)
    stub_product_groups(File.read('spec/fixtures/scripts/internal_events/stages.yml'))
    stub_helper(:fetch_window_size, '50')
  end

  after do
    delete_files(files_to_cleanup)
  end

  def with_cli_thread
    thread = Thread.new { entrypoint_class.new(prompt).run }

    yield thread
  ensure
    # # Debugging tip #1 -- Uncomment me to see full CLI output from the test run!
    # puts prompt.output.string
    thread.exit
  end

  def queue_cli_inputs(keystrokes)
    # # Debugging tip #2 -- Uncomment me to pause execution after test setup and separately run the CLI manually!
    # binding.pry
    prompt.input << keystrokes.join('')
    prompt.input.rewind
  end

  def plain_last_lines(size = nil)
    lines = prompt.output.string.lines
    lines = lines.last(size) if size
    lines
      .join('')
      .gsub(/\e[^\sm]{2,4}[mh]/, '') # Ignore text colors
      .gsub(/(\e\[(2K|1G|1A))+\z/, '') # Remove trailing characters if timeout occurs
  end

  def collect_file_writes(collector)
    allow(File).to receive(:write).and_wrap_original do |original_method, *args, &block|
      filepath = args.first
      collector << filepath

      dirname = Pathname.new(filepath).dirname
      unless dirname.directory?
        FileUtils.mkdir_p dirname
        collector << dirname.to_s
      end

      original_method.call(*args, &block)
    end
  end

  def delete_files(files)
    files.each do |filepath|
      FileUtils.rm_f(Rails.root.join(filepath))
    end
  end
end
