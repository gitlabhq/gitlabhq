# frozen_string_literal: true

require 'fast_spec_helper'
require 'tty/prompt/test'
require_relative '../../../scripts/internal_events/cli'

RSpec.describe Cli, feature_category: :service_ping do
  let(:prompt) { TTY::Prompt::Test.new }
  let(:files_to_cleanup) { [] }

  let(:event1_filepath) { 'config/events/internal_events_cli_used.yml' }
  let(:event1_content) { internal_event_fixture('events/event_with_identifiers.yml') }
  let(:event2_filepath) { 'ee/config/events/internal_events_cli_opened.yml' }
  let(:event2_content) { internal_event_fixture('events/ee_event_without_identifiers.yml') }
  let(:event3_filepath) { 'config/events/internal_events_cli_closed.yml' }
  let(:event3_content) { internal_event_fixture('events/secondary_event_with_identifiers.yml') }

  before do
    stub_milestone('16.6')
    collect_file_writes(files_to_cleanup)
    stub_product_groups(File.read('spec/fixtures/scripts/internal_events/stages.yml'))
    stub_helper(:fetch_window_size, '50')
  end

  after do
    delete_files(files_to_cleanup)
  end

  shared_examples 'creates the right defintion files' do |description, test_case = {}|
    # For expected keystroke mapping, see https://github.com/piotrmurach/tty-reader/blob/master/lib/tty/reader/keys.rb
    let(:keystrokes) { test_case.dig('inputs', 'keystrokes') || [] }
    let(:input_files) { test_case.dig('inputs', 'files') || [] }
    let(:output_files) { test_case.dig('outputs', 'files') || [] }

    subject { run_with_verbose_timeout }

    it "in scenario: #{description}" do
      delete_old_ouputs # just in case
      prep_input_files
      queue_cli_inputs(keystrokes)
      expect_file_creation

      subject
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
  end

  context 'when creating new events' do
    YAML.safe_load(File.read('spec/fixtures/scripts/internal_events/new_events.yml')).each do |test_case|
      it_behaves_like 'creates the right defintion files', test_case['description'], test_case
    end
  end

  context 'when creating new metrics' do
    YAML.safe_load(File.read('spec/fixtures/scripts/internal_events/new_metrics.yml')).each do |test_case|
      it_behaves_like 'creates the right defintion files', test_case['description'], test_case
    end

    context 'when creating a metric from multiple events' do
      let(:events) do
        [{
          action: '00_event1', category: 'InternalEventTracking',
          product_section: 'dev', product_stage: 'plan', product_group: 'optimize'
        }, {
          action: '00_event2', category: 'InternalEventTracking',
          product_section: 'dev', product_stage: 'create', product_group: 'ide'
        }, {
          action: '00_event3', category: 'InternalEventTracking',
          product_section: 'dev', product_stage: 'create', product_group: 'source_code'
        }]
      end

      before do
        events.each do |event|
          File.write("config/events/#{event[:action]}.yml", event.transform_keys(&:to_s).to_yaml)
        end
      end

      it 'filters the product group options based on common section' do
        # Select 00_event1 & #00_event2
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
          "2\n", # Enum-select: Multiple events -- count occurrences of several separate events or interactions
          " ", # Multi-select: __event1
          "\e[B", # Arrow down to: __event2
          " ", # Multi-select: __event2
          "\n", # Submit selections
          "\n", # Select: Weekly/Monthly count of unique users
          "aggregate metric description\n", # Submit description
          "\n", # Accept description for weekly
          "\n" # Copy & continue
        ])

        run_with_timeout

        # Filter down to "dev" options
        expect(plain_last_lines(9)).to eq <<~TEXT.chomp
        ‣ dev:plan:project_management
          dev:plan:product_planning
          dev:plan:knowledge
          dev:plan:optimize
          dev:create:source_code
          dev:create:code_review
          dev:create:ide
          dev:create:editor_extensions
          dev:create:code_creation
        TEXT
      end

      it 'filters the product group options based on common section & stage' do
        # Select 00_event2 & #00_event3
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
          "2\n", # Enum-select: Multiple events -- count occurrences of several separate events or interactions
          "\e[B", # Arrow down to: __event2
          " ", # Multi-select: __event2
          "\e[B", # Arrow down to: __event3
          " ", # Multi-select: __event3
          "\n", # Submit selections
          "\n", # Select: Weekly/Monthly count of unique users
          "aggregate metric description\n", # Submit description
          "\n", # Accept description for weekly
          "\n" # Copy & continue
        ])

        run_with_timeout

        # Filter down to "dev:create" options
        expect(plain_last_lines(5)).to eq <<~TEXT.chomp
        ‣ dev:create:source_code
          dev:create:code_review
          dev:create:ide
          dev:create:editor_extensions
          dev:create:code_creation
        TEXT
      end
    end

    context 'when product group for event no longer exists' do
      let(:event) do
        {
          action: '00_event1', category: 'InternalEventTracking',
          product_section: 'other', product_stage: 'other', product_group: 'other'
        }
      end

      before do
        File.write("config/events/#{event[:action]}.yml", event.transform_keys(&:to_s).to_yaml)
      end

      it 'prompts user to select another group' do
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
          "1\n", # Enum-select: Single event    -- count occurrences of a specific event or user interaction
          "\n", # Select: 00__event1
          "\n", # Select: Weekly/Monthly count of unique users
          "aggregate metric description\n", # Submit description
          "\n", # Accept description for weekly
          "2\n" # Modify attributes
        ])

        run_with_timeout

        # Filter down to "dev" options
        expect(plain_last_lines(50)).to include 'Select one: Which group owns the metric?'
      end
    end

    context 'when creating a metric for an event which has metrics' do
      before do
        File.write(event1_filepath, File.read(event1_content))
      end

      it 'shows all metrics options' do
        select_event_from_list

        expect(plain_last_lines(5)).to eq <<~TEXT.chomp
        ‣ Monthly/Weekly count of unique users [who triggered internal_events_cli_used]
          Monthly/Weekly count of unique projects [where internal_events_cli_used occurred]
          Monthly/Weekly count of unique namespaces [where internal_events_cli_used occurred]
          Monthly/Weekly count of [internal_events_cli_used occurrences]
          Total count of [internal_events_cli_used occurrences]
        TEXT
      end

      context 'with an existing weekly metric' do
        before do
          File.write(
            'ee/config/metrics/counts_7d/count_total_internal_events_cli_used_weekly.yml',
            File.read('spec/fixtures/scripts/internal_events/metrics/ee_total_7d_single_event.yml')
          )
        end

        it 'partially filters metric options' do
          select_event_from_list

          expect(plain_last_lines(6)).to eq <<~TEXT.chomp
          ‣ Monthly/Weekly count of unique users [who triggered internal_events_cli_used]
            Monthly/Weekly count of unique projects [where internal_events_cli_used occurred]
            Monthly/Weekly count of unique namespaces [where internal_events_cli_used occurred]
            Monthly count of [internal_events_cli_used occurrences]
          ✘ Weekly count of [internal_events_cli_used occurrences] (already defined)
            Total count of [internal_events_cli_used occurrences]
          TEXT
        end
      end

      context 'with an existing total metric' do
        before do
          File.write(
            'ee/config/metrics/counts_all/count_total_internal_events_cli_used.yml',
            File.read('spec/fixtures/scripts/internal_events/metrics/ee_total_single_event.yml')
          )
        end

        it 'filters whole metric options' do
          select_event_from_list

          expect(plain_last_lines(5)).to eq <<~TEXT.chomp
          ‣ Monthly/Weekly count of unique users [who triggered internal_events_cli_used]
            Monthly/Weekly count of unique projects [where internal_events_cli_used occurred]
            Monthly/Weekly count of unique namespaces [where internal_events_cli_used occurred]
            Monthly/Weekly count of [internal_events_cli_used occurrences]
          ✘ Total count of [internal_events_cli_used occurrences] (already defined)
          TEXT
        end
      end

      private

      def select_event_from_list
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
          "1\n", # Enum-select: Single event -- count occurrences of a specific event or user interaction
          'internal_events_cli_used', # Filters to this event
          "\n" # Select: config/events/internal_events_cli_used.yml
        ])

        run_with_timeout
      end
    end

    context 'when event excludes identifiers' do
      before do
        File.write(event2_filepath, File.read(event2_content))
      end

      it 'filters unavailable identifiers' do
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
          "1\n", # Enum-select: Single event -- count occurrences of a specific event or user interaction
          'internal_events_cli_opened', # Filters to this event
          "\n" # Select: config/events/internal_events_cli_opened.yml
        ])

        run_with_timeout

        expect(plain_last_lines(5)).to eq <<~TEXT.chomp
        ✘ Monthly/Weekly count of unique users [who triggered internal_events_cli_opened] (user unavailable)
        ✘ Monthly/Weekly count of unique projects [where internal_events_cli_opened occurred] (project unavailable)
        ✘ Monthly/Weekly count of unique namespaces [where internal_events_cli_opened occurred] (namespace unavailable)
        ‣ Monthly/Weekly count of [internal_events_cli_opened occurrences]
          Total count of [internal_events_cli_opened occurrences]
        TEXT
      end
    end

    context 'when all metrics already exist' do
      let(:event) { { action: '00_event1', category: 'InternalEventTracking' } }
      let(:metric) { { options: { 'events' => ['00_event1'] }, events: [{ 'name' => '00_event1' }] } }

      let(:files) do
        [
          ['config/events/00_event1.yml', event],
          ['config/metrics/counts_all/count_total_00_event1.yml', metric.merge(time_frame: 'all')],
          ['config/metrics/counts_7d/count_total_00_event1_weekly.yml', metric.merge(time_frame: '7d')],
          ['config/metrics/counts_28d/count_total_00_event1_monthly.yml', metric.merge(time_frame: '28d')]
        ]
      end

      before do
        files.each do |path, content|
          File.write(path, content.transform_keys(&:to_s).to_yaml)
        end
      end

      it 'exits the script and directs user to search for existing metrics' do
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
          "1\n", # Enum-select: Single event -- count occurrences of a specific event or user interaction
          '00_event1', # Filters to this event
          "\n" # Select: config/events/00_event1.yml
        ])

        run_with_timeout

        expect(plain_last_lines(15)).to include 'Looks like the potential metrics for this event ' \
                                                'either already exist or are unsupported.'
      end
    end
  end

  context 'when showing usage examples' do
    let(:expected_example_prompt) do
      <<~TEXT.chomp
      Select one: Select a use-case to view examples for: (Press ↑/↓ arrow or 1-8 number to move and Enter to select)
      ‣ 1. ruby/rails
        2. rspec
        3. javascript (vue)
        4. javascript (plain)
        5. vue template
        6. haml
        7. View examples for a different event
        8. Exit
      TEXT
    end

    context 'for an event with identifiers' do
      let(:expected_rails_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS

        Gitlab::InternalEvents.track_event(
          'internal_events_cli_used',
          project: project,
          namespace: project.namespace,
          user: user
        )

        --------------------------------------------------
        TEXT
      end

      let(:expected_rspec_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RSPEC

        it_behaves_like 'internal event tracking' do
          let(:event) { 'internal_events_cli_used' }
          let(:project) { project }
          let(:namespace) { project.namespace }
          let(:user) { user }
        end

        --------------------------------------------------
        TEXT
      end

      before do
        File.write(event1_filepath, File.read(event1_content))
      end

      it 'shows backend examples' do
        queue_cli_inputs([
          "3\n", # Enum-select: View Usage -- look at code examples for an existing event
          'internal_events_cli_used', # Filters to this event
          "\n", # Select: config/events/internal_events_cli_used.yml
          "\n", # Select: ruby/rails
          "\e[B", # Arrow down to: rspec
          "\n", # Select: rspec
          "8\n" # Exit
        ])

        run_with_timeout

        output = plain_last_lines(100)

        expect(output).to include expected_example_prompt
        expect(output).to include expected_rails_example
        expect(output).to include expected_rspec_example
      end
    end

    context 'for an event without identifiers' do
      let(:expected_rails_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS

        Gitlab::InternalEvents.track_event('internal_events_cli_opened')

        --------------------------------------------------
        TEXT
      end

      let(:expected_rspec_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RSPEC

        it_behaves_like 'internal event tracking' do
          let(:event) { 'internal_events_cli_opened' }
        end

        --------------------------------------------------
        TEXT
      end

      let(:expected_vue_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        // VUE

        <script>
        import { InternalEvents } from '~/tracking';
        import { GlButton } from '@gitlab/ui';

        const trackingMixin = InternalEvents.mixin();

        export default {
          mixins: [trackingMixin],
          components: { GlButton },
          methods: {
            performAction() {
              this.trackEvent('internal_events_cli_opened');
            },
          },
        };
        </script>

        <template>
          <gl-button @click=performAction>Click Me</gl-button>
        </template>

        --------------------------------------------------
        TEXT
      end

      let(:expected_js_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        // FRONTEND -- RAW JAVASCRIPT

        import { InternalEvents } from '~/tracking';

        export const performAction = () => {
          InternalEvents.trackEvent('internal_events_cli_opened');

          return true;
        };

        --------------------------------------------------
        TEXT
      end

      let(:expected_vue_template_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        // VUE TEMPLATE -- ON-CLICK

        <script>
        import { GlButton } from '@gitlab/ui';

        export default {
          components: { GlButton }
        };
        </script>

        <template>
          <gl-button data-event-tracking="internal_events_cli_opened">
            Click Me
          </gl-button>
        </template>

        --------------------------------------------------
        // VUE TEMPLATE -- ON-LOAD

        <script>
        import { GlButton } from '@gitlab/ui';

        export default {
          components: { GlButton }
        };
        </script>

        <template>
          <gl-button data-event-tracking-load="internal_events_cli_opened">
            Click Me
          </gl-button>
        </template>

        --------------------------------------------------
        TEXT
      end

      let(:expected_haml_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # HAML -- ON-CLICK

        .gl-display-inline-block{ data: { event_tracking: 'internal_events_cli_opened' } }
          = _('Important Text')

        --------------------------------------------------
        # HAML -- COMPONENT ON-CLICK

        = render Pajamas::ButtonComponent.new(button_options: { data: { event_tracking: 'internal_events_cli_opened' } })

        --------------------------------------------------
        # HAML -- COMPONENT ON-LOAD

        = render Pajamas::ButtonComponent.new(button_options: { data: { event_tracking_load: true, event_tracking: 'internal_events_cli_opened' } })

        --------------------------------------------------
        TEXT
      end

      before do
        File.write(event2_filepath, File.read(event2_content))
      end

      it 'shows all examples' do
        queue_cli_inputs([
          "3\n", # Enum-select: View Usage -- look at code examples for an existing event
          'internal_events_cli_opened', # Filters to this event
          "\n", # Select: config/events/internal_events_cli_used.yml
          "\n", # Select: ruby/rails
          "\e[B", # Arrow down to: rspec
          "\n", # Select: rspec
          "\e[B", # Arrow down to: js vue
          "\n", # Select: js vue
          "\e[B", # Arrow down to: js plain
          "\n", # Select: js plain
          "\e[B", # Arrow down to: vue template
          "\n", # Select: vue template
          "\e[B", # Arrow down to: haml
          "\n", # Select: haml
          "8\n" # Exit
        ])

        run_with_timeout

        output = plain_last_lines(1000)

        expect(output).to include expected_example_prompt
        expect(output).to include expected_rails_example
        expect(output).to include expected_rspec_example
        expect(output).to include expected_vue_example
        expect(output).to include expected_js_example
        expect(output).to include expected_vue_template_example
        expect(output).to include expected_haml_example
      end
    end

    context 'when viewing examples for multiple events' do
      let(:expected_event1_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS

        Gitlab::InternalEvents.track_event(
          'internal_events_cli_used',
          project: project,
          namespace: project.namespace,
          user: user
        )

        --------------------------------------------------
        TEXT
      end

      let(:expected_event2_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS

        Gitlab::InternalEvents.track_event('internal_events_cli_opened')

        --------------------------------------------------
        TEXT
      end

      before do
        File.write(event1_filepath, File.read(event1_content))
        File.write(event2_filepath, File.read(event2_content))
      end

      it 'switches between events gracefully' do
        queue_cli_inputs([
          "3\n", # Enum-select: View Usage -- look at code examples for an existing event
          'internal_events_cli_used', # Filters to this event
          "\n", # Select: config/events/internal_events_cli_used.yml
          "\n", # Select: ruby/rails
          "7\n", # Select: View examples for a different event
          'internal_events_cli_opened', # Filters to this event
          "\n", # Select: config/events/internal_events_cli_opened.yml
          "\n", # Select: ruby/rails
          "8\n" # Exit
        ])

        run_with_timeout

        output = plain_last_lines(300)

        expect(output).to include expected_example_prompt
        expect(output).to include expected_event1_example
        expect(output).to include expected_event2_example
      end
    end
  end

  context 'when offline' do
    before do
      stub_product_groups(nil)
    end

    it_behaves_like 'creates the right defintion files',
      'Creates a new event with product stage/section/group input manually' do
      let(:keystrokes) do
        [
          "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
          "Internal Event CLI is opened\n", # Submit description
          "internal_events_cli_opened\n", # Submit action name
          "6\n", # Select: None
          "\n", # Skip MR URL
          "analytics\n", # Input section
          "monitor\n", # Input stage
          "analytics_instrumentation\n", # Input group
          "2\n", # Select [premium, ultimate]
          "y\n", # Create file
          "3\n" # Exit
        ]
      end

      let(:output_files) { [{ 'path' => event2_filepath, 'content' => event2_content }] }
    end

    it_behaves_like 'creates the right defintion files',
      'Creates a new metric with product stage/section/group input manually' do
      let(:keystrokes) do
        [
          "2\n", # Enum-select: New Metric   -- calculate how often one or more existing events occur over time
          "2\n", # Enum-select: Multiple events -- count occurrences of several separate events or interactions
          'internal_events_cli', # Filters to the relevant events
          ' ', # Multi-select: internal_events_cli_closed
          "\e[B", # Arrow down to: internal_events_cli_used
          ' ', # Multi-select: internal_events_cli_used
          "\n", # Submit selections
          "\e[B", # Arrow down to: Weekly count of unique projects
          "\n", # Select: Weekly count of unique projects
          "where a defition file was created with the CLI\n", # Input description
          "\n", # Submit weekly description for monthly
          "2\n", # Select: Modify attributes
          "\n", # Accept section
          "\n", # Accept stage
          "\n", # Accept group
          "\n", # Skip URL
          "1\n", # Select: [free, premium, ultimate]
          "y\n", # Create file
          "y\n", # Create file
          "2\n" # Exit
        ]
      end

      let(:input_files) do
        [
          { 'path' => event1_filepath, 'content' => event1_content },
          { 'path' => event3_filepath, 'content' => event3_content }
        ]
      end

      let(:output_files) do
        # rubocop:disable Layout/LineLength -- Long filepaths read better unbroken
        [{
          'path' => 'config/metrics/counts_28d/count_distinct_project_id_from_internal_events_cli_closed_and_internal_events_cli_used_monthly.yml',
          'content' => 'spec/fixtures/scripts/internal_events/metrics/project_id_28d_multiple_events.yml'
        }, {
          'path' => 'config/metrics/counts_7d/count_distinct_project_id_from_internal_events_cli_closed_and_internal_events_cli_used_weekly.yml',
          'content' => 'spec/fixtures/scripts/internal_events/metrics/project_id_7d_multiple_events.yml'
        }]
        # rubocop:enable Layout/LineLength
      end
    end
  end

  context 'when window size is unavailable' do
    before do
      # `tput <cmd>` returns empty string on error
      stub_helper(:fetch_window_size, '')
      stub_helper(:fetch_window_height, '')
    end

    it_behaves_like 'creates the right defintion files',
      'Terminal size does not prevent file creation' do
      let(:keystrokes) do
        [
          "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
          "Internal Event CLI is opened\n", # Submit description
          "internal_events_cli_opened\n", # Submit action name
          "6\n", # Select: None
          "\n", # Skip MR URL
          "instrumentation\n", # Filter & select group
          "2\n", # Select [premium, ultimate]
          "y\n", # Create file
          "3\n" # Exit
        ]
      end

      let(:output_files) { [{ 'path' => event2_filepath, 'content' => event2_content }] }
    end
  end

  context "when user doesn't know what they're trying to do" do
    it "handles when user isn't trying to track product usage" do
      queue_cli_inputs([
        "4\n", # Enum-select: ...am I in the right place?
        "n\n" # No --> Are you trying to track customer usage of a GitLab feature?
      ])

      run_with_timeout

      expect(plain_last_lines(50)).to include("Oh no! This probably isn't the tool you need!")
    end

    it "handles when product usage can't be tracked with events" do
      queue_cli_inputs([
        "4\n", # Enum-select: ...am I in the right place?
        "y\n", # Yes --> Are you trying to track customer usage of a GitLab feature?
        "n\n" # No --> Can usage for the feature be measured by tracking a specific user action?
      ])

      run_with_timeout

      expect(plain_last_lines(50)).to include("Oh no! This probably isn't the tool you need!")
    end

    it 'handles when user needs to add a new event' do
      queue_cli_inputs([
        "4\n", # Enum-select: ...am I in the right place?
        "y\n", # Yes --> Are you trying to track customer usage of a GitLab feature?
        "y\n", # Yes --> Can usage for the feature be measured by tracking a specific user action?
        "n\n", # No --> Is the event already tracked?
        "n\n" # No --> Ready to start?
      ])

      run_with_timeout

      expect(plain_last_lines(30)).to include("Okay! The next step is adding a new event! (~5 min)")
    end

    it 'handles when user needs to add a new metric' do
      queue_cli_inputs([
        "4\n", # Enum-select: ...am I in the right place?
        "y\n", # Yes --> Are you trying to track customer usage of a GitLab feature?
        "y\n", # Yes --> Can usage for the feature be measured by tracking a specific user action?
        "y\n", # Yes --> Is the event already tracked?
        "n\n" # No --> Ready to start?
      ])

      run_with_timeout

      expect(plain_last_lines(30)).to include("Amazing! The next step is adding a new metric! (~8 min)")
    end
  end

  private

  def queue_cli_inputs(keystrokes)
    prompt.input << keystrokes.join('')
    prompt.input.rewind
  end

  def run_with_timeout(duration = 1)
    Timeout.timeout(duration) { described_class.new(prompt).run }
  rescue Timeout::Error
    # Timeout is needed to break out of the CLI, but we may want
    # to make assertions afterwards
  end

  def run_with_verbose_timeout(duration = 1)
    Timeout.timeout(duration) { described_class.new(prompt).run }
  rescue Timeout::Error => e
    # Re-raise error so CLI output is printed with the error
    message = <<~TEXT
    Awaiting input too long. Entire CLI output:

    #{
      prompt.output.string.lines
        .map { |line| "\e[0;37m#{line}\e[0m" } # wrap in white
        .join('')
        .gsub("\e[1G", "\e[1G       ") # align to error indent
    }


    TEXT

    raise e.class, message, e.backtrace
  end

  def plain_last_lines(size)
    prompt.output.string
      .lines
      .last(size)
      .join('')
      .gsub(/\e[^\sm]{2,4}[mh]/, '')
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

  def stub_milestone(milestone)
    stub_const("InternalEventsCli::Helpers::MILESTONE", milestone)
  end

  def stub_product_groups(body)
    allow(Net::HTTP).to receive(:get)
      .with(URI('https://gitlab.com/gitlab-com/www-gitlab-com/-/raw/master/data/stages.yml'))
      .and_return(body)
  end

  def stub_helper(helper, value)
    # rubocop:disable RSpec/AnyInstanceOf -- 'Next' helper not included in fast_spec_helper & next is insufficient
    allow_any_instance_of(InternalEventsCli::Helpers).to receive(helper).and_return(value)
    # rubocop:enable RSpec/AnyInstanceOf
  end

  def delete_files(files)
    files.each do |filepath|
      FileUtils.rm_f(Rails.root.join(filepath))
    end
  end

  def internal_event_fixture(filepath)
    Rails.root.join('spec', 'fixtures', 'scripts', 'internal_events', filepath)
  end
end
