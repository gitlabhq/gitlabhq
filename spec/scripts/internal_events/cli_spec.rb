# frozen_string_literal: true

require 'spec_helper'
require 'tty/prompt/test'
require_relative '../../../scripts/internal_events/cli'

# Debugging tips:
# 1. Include a `binding.pry` at the start of #queue_cli_inputs to pause execution & run the script manually
#       -> because these tests add/remove fixtures from the actual definition directories,
#          the CLI can run with the exact same initial state in another window
# 2. Add `puts prompt.output.string` before `thread.exit` to see the full output from the test run
RSpec.describe Cli, feature_category: :service_ping do
  include WaitHelpers

  let(:prompt) { GitlabPrompt.new(TTY::Prompt::Test.new) }
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

  # Shared examples used for examples defined in new_events.yml & new_metrics.yml fixtures.
  # Note: Expects CLI to be exited using the 'Exit' option or completing definition flow
  shared_examples 'creates the right definition files' do |description, test_case = {}|
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

  shared_examples 'definition fixtures are valid' do |directory, schema_path|
    let(:schema) { ::JSONSchemer.schema(Pathname(schema_path)) }
    # The generator can return an invalid definition if the user skips the MR link
    let(:expected_errors) { a_hash_including('data_pointer' => '/introduced_by_url', 'data' => 'TODO') }

    it "for #{directory}", :aggregate_failures do
      Dir[Rails.root.join('spec', 'fixtures', 'scripts', 'internal_events', directory, '*.yml')].each do |filepath|
        attributes = YAML.safe_load(File.read(filepath))
        errors = schema.validate(attributes).to_a

        error_message = <<~TEXT
        Unexpected validation errors in: #{filepath}
        #{errors.map { |e| JSONSchemer::Errors.pretty(e) }.join("\n")}
        TEXT

        if attributes['introduced_by_url'] == 'TODO'
          expect(errors).to contain_exactly(expected_errors), error_message
        else
          expect(errors).to be_empty, error_message
        end
      end
    end
  end

  it_behaves_like 'definition fixtures are valid', 'events', 'config/events/schema.json'
  it_behaves_like 'definition fixtures are valid', 'metrics', 'config/metrics/schema/base.json'

  context 'when creating new events' do
    YAML.safe_load(File.read('spec/fixtures/scripts/internal_events/new_events.yml')).each do |test_case|
      it_behaves_like 'creates the right definition files', test_case['description'], test_case
    end

    context 'with invalid event name' do
      it 'prompts user to select another name' do
        queue_cli_inputs([
          "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
          "Engineer uses Internal Event CLI to define a new event\n", # Submit description
          "badDDD_ event (name) with // prob.lems\n" # Submit action name
        ])

        with_cli_thread do
          expect { prompt.output.string }.to eventually_include_cli_text('Invalid event name.')
        end
      end
    end

    context 'with a valid event name' do
      it 'continues to the next step' do
        queue_cli_inputs([
          "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
          "Engineer uses Internal Event CLI to define a new event\n", # Submit description
          "a_totally_fine_0123456789_name\n" # Submit action name
        ])

        with_cli_thread do
          expect { prompt.output.string }.to eventually_include_cli_text('Step 3 / 7')
        end
      end
    end
  end

  context 'when creating new metrics' do
    YAML.safe_load(File.read('spec/fixtures/scripts/internal_events/new_metrics.yml')).each do |test_case|
      it_behaves_like 'creates the right definition files', test_case['description'], test_case
    end

    context 'when creating a metric from multiple events' do
      # all of these product_groups belong to 'dev' product_section
      let(:events) do
        [{
          action: '00_event1', internal_events: true, product_group: 'optimize'
        }, {
          action: '00_event2', internal_events: true, product_group: 'ide'
        }, {
          action: '00_event3', internal_events: true, product_group: 'source_code'
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
          "\n" # Accept description for weekly
        ])

        # Filter down to "dev" options
        expected_output = <<~TEXT.chomp
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

        with_cli_thread do
          expect { plain_last_lines(9) }.to eventually_equal_cli_text(expected_output)
        end
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
          "\n" # Accept description for weekly
        ])

        # Filter down to "dev:create" options
        expected_output = <<~TEXT.chomp
        ‣ dev:create:source_code
          dev:create:code_review
          dev:create:ide
          dev:create:editor_extensions
          dev:create:code_creation
        TEXT

        with_cli_thread do
          expect { plain_last_lines(5) }.to eventually_equal_cli_text(expected_output)
        end
      end
    end

    context 'when product group for event no longer exists' do
      let(:event) do
        {
          action: '00_event1', product_group: 'other'
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

        # Filter down to "dev" options
        with_cli_thread do
          expect { plain_last_lines(50) }.to eventually_include_cli_text('Select one: Which group owns the metric?')
        end
      end
    end

    context 'when creating a metric for an event which has metrics' do
      before do
        File.write(event1_filepath, File.read(event1_content))
      end

      it 'shows all metrics options' do
        select_event_from_list

        expected_output = <<~TEXT.chomp
        ‣ Monthly/Weekly count of unique users [who triggered internal_events_cli_used]
          Monthly/Weekly count of unique projects [where internal_events_cli_used occurred]
          Monthly/Weekly count of unique namespaces [where internal_events_cli_used occurred]
          Monthly/Weekly count of [internal_events_cli_used occurrences]
          Total count of [internal_events_cli_used occurrences]
        TEXT

        with_cli_thread do
          expect { plain_last_lines(5) }.to eventually_equal_cli_text(expected_output)
        end
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

          expected_output = <<~TEXT.chomp
          ‣ Monthly/Weekly count of unique users [who triggered internal_events_cli_used]
            Monthly/Weekly count of unique projects [where internal_events_cli_used occurred]
            Monthly/Weekly count of unique namespaces [where internal_events_cli_used occurred]
            Monthly count of [internal_events_cli_used occurrences]
          ✘ Weekly count of [internal_events_cli_used occurrences] (already defined)
            Total count of [internal_events_cli_used occurrences]
          TEXT

          with_cli_thread do
            expect { plain_last_lines(6) }.to eventually_equal_cli_text(expected_output)
          end
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

          expected_output = <<~TEXT.chomp
          ‣ Monthly/Weekly count of unique users [who triggered internal_events_cli_used]
            Monthly/Weekly count of unique projects [where internal_events_cli_used occurred]
            Monthly/Weekly count of unique namespaces [where internal_events_cli_used occurred]
            Monthly/Weekly count of [internal_events_cli_used occurrences]
          ✘ Total count of [internal_events_cli_used occurrences] (already defined)
          TEXT

          with_cli_thread do
            expect { plain_last_lines(5) }.to eventually_equal_cli_text(expected_output)
          end
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
      end
    end

    context 'when creating a metric for multiple events which have metrics' do
      before do
        File.write(event1_filepath, File.read(event1_content))
        File.write(event3_filepath, File.read(event3_content))

        # existing metrics which use both events
        File.write(
          'config/metrics/counts_7d/' \
            'count_distinct_project_id_from_internal_events_cli_closed_and_internal_events_cli_used_weekly.yml',
          File.read('spec/fixtures/scripts/internal_events/metrics/project_id_7d_multiple_events.yml')
        )
        File.write(
          'config/metrics/counts_28d/' \
            'count_distinct_project_id_from_internal_events_cli_closed_and_internal_events_cli_used_monthly.yml',
          File.read('spec/fixtures/scripts/internal_events/metrics/project_id_28d_multiple_events.yml')
        )

        # Non-conflicting metric which uses only one of the events
        File.write(
          'config/metrics/counts_all/count_total_internal_events_cli_used.yml',
          File.read('spec/fixtures/scripts/internal_events/metrics/total_single_event.yml')
        )
      end

      it 'partially filters metric options' do
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
          "2\n", # Enum-select:  Multiple events -- count occurrences of several separate events or interactions
          'internal_events_cli', # Filters to the relevant events
          ' ', # Multi-select: internal_events_cli_closed
          "\e[B", # Arrow down to: internal_events_cli_used
          ' ', # Multi-select: internal_events_cli_used
          "\n" # Complete selections
        ])

        expected_output = <<~TEXT.chomp
        ‣ Monthly/Weekly count of unique users [who triggered any of 2 events]
        ✘ Monthly/Weekly count of unique projects [where any of 2 events occurred] (already defined)
          Monthly/Weekly count of unique namespaces [where any of 2 events occurred]
          Monthly/Weekly count of [any of 2 events occurrences]
          Total count of [any of 2 events occurrences]
        TEXT

        with_cli_thread do
          expect { plain_last_lines(5) }.to eventually_equal_cli_text(expected_output)
        end
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

        expected_output = <<~TEXT.chomp
        ✘ Monthly/Weekly count of unique users [who triggered internal_events_cli_opened] (user unavailable)
        ✘ Monthly/Weekly count of unique projects [where internal_events_cli_opened occurred] (project unavailable)
        ✘ Monthly/Weekly count of unique namespaces [where internal_events_cli_opened occurred] (namespace unavailable)
        ‣ Monthly/Weekly count of [internal_events_cli_opened occurrences]
          Total count of [internal_events_cli_opened occurrences]
        TEXT

        with_cli_thread do
          expect { plain_last_lines(5) }.to eventually_equal_cli_text(expected_output)
        end
      end
    end

    context 'when all metrics already exist' do
      let(:event) { { action: '00_event1' } }
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

        expected_output = 'Looks like the potential metrics for this event either already exist or are unsupported.'

        with_cli_thread do
          expect { plain_last_lines(15) }.to eventually_include_cli_text(expected_output)
        end
      end
    end
  end

  context 'when showing usage examples' do
    let(:expected_example_prompt) do
      <<~TEXT.chomp
      Select one: Select a use-case to view examples for: (Press ↑/↓ arrow to move, Enter to select and letters to filter)
      ‣ 1. ruby/rails
        2. rspec
        3. javascript (vue)
        4. javascript (plain)
        5. vue template
        6. haml
        7. Manual testing in GDK
        8. Data verification in Tableau
        9. View examples for a different event
        10. Exit
      TEXT
    end

    context 'for an event with identifiers and metrics' do
      let(:expected_rails_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS

        include Gitlab::InternalEventsTracking

        track_internal_event(
          'internal_events_cli_used',
          project: project,
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
          let(:project) { create(:project) }
          let(:user) { create(:user) }
        end

        --------------------------------------------------
        TEXT
      end

      let(:expected_gdk_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS CONSOLE -- generate service ping payload, including most recent usage data

        require_relative 'spec/support/helpers/service_ping_helpers.rb'

        # Get current value of a metric
        ServicePingHelpers.get_current_usage_metric_value('redis_hll_counters.count_distinct_user_id_from_internal_events_cli_used_weekly')

        # View entire service ping payload
        ServicePingHelpers.get_current_service_ping_payload
        --------------------------------------------------
        TEXT
      end

      let(:expected_tableau_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # GROUP DASHBOARDS -- view all service ping metrics for a specific group

        analytics_instrumentation: https://10az.online.tableau.com/#/site/gitlab/views/PDServicePingExplorationDashboard/MetricExplorationbyGroup?Group%20Name=analytics_instrumentation&Stage%20Name=monitor

        --------------------------------------------------
        # METRIC TRENDS -- view data for a service ping metric for internal_events_cli_used

        redis_hll_counters.count_distinct_user_id_from_internal_events_cli_used_weekly: https://10az.online.tableau.com/#/site/gitlab/views/PDServicePingExplorationDashboard/MetricTrend?Metrics%20Path=redis_hll_counters.count_distinct_user_id_from_internal_events_cli_used_weekly

        --------------------------------------------------
        Note: The metric dashboard links can also be accessed from https://metrics.gitlab.com/

        Not what you're looking for? Check this doc:
          - https://docs.gitlab.com/ee/development/internal_analytics/#data-discovery
        TEXT
      end

      before do
        File.write(event1_filepath, File.read(event1_content))
        File.write(
          'config/metrics/counts_7d/count_distinct_user_id_from_internal_events_cli_used_weekly.yml',
          File.read('spec/fixtures/scripts/internal_events/metrics/user_id_7d_single_event.yml')
        )
      end

      it 'shows backend examples' do
        queue_cli_inputs([
          "3\n", # Enum-select: View Usage -- look at code examples for an existing event
          'internal_events_cli_used', # Filters to this event
          "\n", # Select: config/events/internal_events_cli_used.yml
          "\n", # Select: ruby/rails
          "\e[B", # Arrow down to: rspec
          "\n", # Select: rspec
          "7\n", # Select: Manual testing: check current values of metrics from rails console (any data source)
          "8\n", # Select: Data verification in Tableau
          "Exit", # Filters to this item
          "\n" # select: Exit
        ])

        with_cli_thread do
          expect { plain_last_lines(200) }.to eventually_include_cli_text(
            expected_example_prompt,
            expected_rails_example,
            expected_rspec_example,
            expected_gdk_example,
            expected_tableau_example
          )
        end
      end
    end

    context 'for an event without identifiers' do
      let(:expected_rails_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS

        include Gitlab::InternalEventsTracking

        track_internal_event('internal_events_cli_opened')

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

        .inline-block{ data: { event_tracking: 'internal_events_cli_opened' } }
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

      let(:expected_gdk_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # TERMINAL -- monitor events & changes to service ping metrics as they occur

        1. From `gitlab/` directory, run the monitor script:

        bin/rails runner scripts/internal_events/monitor.rb internal_events_cli_opened

        2. View metric updates within the terminal

        3. [Optional] Configure gdk with snowplow micro to see individual events: https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/snowplow_micro.md

        --------------------------------------------------
        # RAILS CONSOLE -- generate service ping payload, including most recent usage data

        require_relative 'spec/support/helpers/service_ping_helpers.rb'

        # Get current value of a metric
        # Warning: There are no metrics for internal_events_cli_opened yet. When there are, replace <key_path> below.
        ServicePingHelpers.get_current_usage_metric_value(<key_path>)

        # View entire service ping payload
        ServicePingHelpers.get_current_service_ping_payload
        --------------------------------------------------
        Need to test something else? Check these docs:
        - https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/local_setup_and_debugging.html
        - https://docs.gitlab.com/ee/development/internal_analytics/service_ping/troubleshooting.html
        - https://docs.gitlab.com/ee/development/internal_analytics/review_guidelines.html
        TEXT
      end

      let(:expected_tableau_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # GROUP DASHBOARDS -- view all service ping metrics for a specific group

        # Warning: There are no metrics for internal_events_cli_opened yet.
        analytics_instrumentation: https://10az.online.tableau.com/#/site/gitlab/views/PDServicePingExplorationDashboard/MetricExplorationbyGroup?Group%20Name=analytics_instrumentation&Stage%20Name=monitor

        --------------------------------------------------
        Note: The metric dashboard links can also be accessed from https://metrics.gitlab.com/

        Not what you're looking for? Check this doc:
          - https://docs.gitlab.com/ee/development/internal_analytics/#data-discovery
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
          "\e[B", # Arrow down to: gdk
          "\n", # Select: gdk
          "\e[B", # Arrow down to: tableau
          "\n", # Select: tableau
          "Exit", # Filters to this item
          "\n" # select: Exit
        ])

        with_cli_thread do
          expect { plain_last_lines }.to eventually_include_cli_text(
            expected_example_prompt,
            expected_rails_example,
            expected_rspec_example,
            expected_vue_example,
            expected_js_example,
            expected_vue_template_example,
            expected_haml_example,
            expected_gdk_example,
            expected_tableau_example
          )
        end
      end
    end

    context 'when viewing examples for multiple events' do
      let(:expected_event1_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS

        include Gitlab::InternalEventsTracking

        track_internal_event(
          'internal_events_cli_used',
          project: project,
          user: user
        )

        --------------------------------------------------
        TEXT
      end

      let(:expected_event2_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS

        include Gitlab::InternalEventsTracking

        track_internal_event('internal_events_cli_opened')

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
          "9\n", # Select: View examples for a different event
          'internal_events_cli_opened', # Filters to this event
          "\n", # Select: config/events/internal_events_cli_opened.yml
          "\n", # Select: ruby/rails
          "Exit", # Filters to this item
          "\n" # select: Exit
        ])

        with_cli_thread do
          expect { plain_last_lines }.to eventually_include_cli_text(
            expected_example_prompt,
            expected_event1_example,
            expected_event2_example
          )
        end
      end
    end

    context 'for an event with additional properties' do
      let(:event_filepath) { 'config/events/internal_events_cli_used.yml' }
      let(:event_content) { internal_event_fixture('events/event_with_additional_properties.yml') }

      let(:expected_rails_example) do
        <<~TEXT.chomp
        --------------------------------------------------
        # RAILS

        include Gitlab::InternalEventsTracking

        track_internal_event(
          'internal_events_cli_used',
          project: project,
          user: user,
          additional_properties: {
            label: 'string', # TODO
            value: 72 # Time the CLI ran before closing (seconds)
          }
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
          let(:project) { create(:project) }
          let(:user) { create(:user) }
          let(:additional_properties) do
            {
              label: 'string',
              value: 72
            }
          end
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
              this.trackEvent(
                'internal_events_cli_used',
                {
                  label: 'string', // TODO
                  value: 72, // Time the CLI ran before closing (seconds)
                },
              );
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
          InternalEvents.trackEvent(
            'internal_events_cli_used',
            {
              label: 'string', // TODO
              value: 72, // Time the CLI ran before closing (seconds)
            },
          );

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
          <gl-button
            data-event-tracking="internal_events_cli_used"
            data-event-label="string"
            data-event-value=72
          >
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
          <gl-button
            data-event-tracking-load="internal_events_cli_used"
            data-event-label="string"
            data-event-value=72
          >
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

        .inline-block{ data: { event_tracking: 'internal_events_cli_used', event_label: 'string', event_value: 72 } }
          = _('Important Text')

        --------------------------------------------------
        # HAML -- COMPONENT ON-CLICK

        = render Pajamas::ButtonComponent.new(button_options: { data: { event_tracking: 'internal_events_cli_used', event_label: 'string', event_value: 72 } })

        --------------------------------------------------
        # HAML -- COMPONENT ON-LOAD

        = render Pajamas::ButtonComponent.new(button_options: { data: { event_tracking_load: true, event_tracking: 'internal_events_cli_used', event_label: 'string', event_value: 72 } })

        --------------------------------------------------
        TEXT
      end

      before do
        File.write(event_filepath, File.read(event_content))
      end

      it 'shows examples with additional properties included' do
        queue_cli_inputs([
          "3\n", # Enum-select: View Usage -- look at code examples for an existing event
          'internal_events_cli_used', # Filters to this event
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
          "Exit", # Filters to this item
          "\n" # select: Exit
        ])

        with_cli_thread do
          expect { plain_last_lines }.to eventually_include_cli_text(
            expected_rails_example,
            expected_rspec_example,
            expected_vue_example,
            expected_js_example,
            expected_vue_template_example,
            expected_haml_example
          )
        end
      end
    end
  end

  context 'when offline' do
    before do
      stub_product_groups(nil)
    end

    it_behaves_like 'creates the right definition files',
      'Creates a new event with product stage/section/group input manually' do
      let(:keystrokes) do
        [
          "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
          "Internal Event CLI is opened\n", # Submit description
          "internal_events_cli_opened\n", # Submit action name
          "7\n", # Select: None
          "\n", # Select: None! Continue to next section!
          "\n", # Skip MR URL
          "analytics_instrumentation\n", # Input group
          "2\n", # Select [premium, ultimate]
          "y\n", # Create file
          "4\n" # Exit
        ]
      end

      let(:output_files) { [{ 'path' => event2_filepath, 'content' => event2_content }] }
    end

    it_behaves_like 'creates the right definition files',
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
          "\n", # Accept group
          "\n", # Skip URL
          "1\n", # Select: [free, premium, ultimate]
          "y\n", # Create file
          "y\n", # Create file
          "5\n" # Exit
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

    it_behaves_like 'creates the right definition files',
      'Terminal size does not prevent file creation' do
      let(:keystrokes) do
        [
          "1\n", # Enum-select: New Event -- start tracking when an action or scenario occurs on gitlab instances
          "Internal Event CLI is opened\n", # Submit description
          "internal_events_cli_opened\n", # Submit action name
          "7\n", # Select: None
          "\n", # Select: None! Continue to next section!
          "\n", # Skip MR URL
          "instrumentation\n", # Filter & select group
          "2\n", # Select [premium, ultimate]
          "y\n", # Create file
          "4\n" # Exit
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

      with_cli_thread do
        expect { plain_last_lines(50) }.to eventually_include_cli_text("Oh no! This probably isn't the tool you need!")
      end
    end

    it "handles when product usage can't be tracked with events" do
      queue_cli_inputs([
        "4\n", # Enum-select: ...am I in the right place?
        "y\n", # Yes --> Are you trying to track customer usage of a GitLab feature?
        "n\n" # No --> Can usage for the feature be measured by tracking a specific user action?
      ])

      with_cli_thread do
        expect { plain_last_lines(50) }.to eventually_include_cli_text("Oh no! This probably isn't the tool you need!")
      end
    end

    it 'handles when user needs to add a new event' do
      queue_cli_inputs([
        "4\n", # Enum-select: ...am I in the right place?
        "y\n", # Yes --> Are you trying to track customer usage of a GitLab feature?
        "y\n", # Yes --> Can usage for the feature be measured by tracking a specific user action?
        "n\n", # No --> Is the event already tracked?
        "n\n" # No --> Ready to start?
      ])

      with_cli_thread do
        expect { plain_last_lines(30) }
          .to eventually_include_cli_text("Okay! The next step is adding a new event! (~5-10 min)")
      end
    end

    it 'handles when user needs to add a new metric' do
      queue_cli_inputs([
        "4\n", # Enum-select: ...am I in the right place?
        "y\n", # Yes --> Are you trying to track customer usage of a GitLab feature?
        "y\n", # Yes --> Can usage for the feature be measured by tracking a specific user action?
        "y\n", # Yes --> Is the event already tracked?
        "n\n" # No --> Ready to start?
      ])

      with_cli_thread do
        expect { plain_last_lines(30) }
          .to eventually_include_cli_text("Amazing! The next step is adding a new metric! (~8-15 min)")
      end
    end
  end

  private

  def queue_cli_inputs(keystrokes)
    # # Debugging tip #1 -- Uncomment me to pause execution after test setup and separately run the CLI manually!
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

  def stub_milestone(milestone)
    stub_const("InternalEventsCli::Helpers::MILESTONE", milestone)
  end

  def stub_product_groups(body)
    allow(Net::HTTP).to receive(:get)
      .with(URI(InternalEventsCli::Helpers::GroupOwnership::STAGES_YML))
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

  def with_cli_thread
    thread = Thread.new { described_class.new(prompt).run }

    yield thread
  ensure
    # # Debugging tip #2 -- Uncomment me to see full CLI output from the test run!
    # puts prompt.output.string
    thread.exit
  end
end
