# frozen_string_literal: true

require 'spec_helper'
require 'tty/prompt/test'
require_relative '../../../../../scripts/internal_events/cli'

RSpec.describe 'InternalEventsCli::Flows::MetricDefiner', :aggregate_failures, feature_category: :service_ping do
  include_context 'when running the Internal Events Cli'

  let_it_be(:event1_filepath) { 'config/events/internal_events_cli_used.yml' }
  let_it_be(:event1_content) { internal_event_fixture('events/event_with_identifiers.yml') }
  let_it_be(:event2_filepath) { 'ee/config/events/internal_events_cli_opened.yml' }
  let_it_be(:event2_content) { internal_event_fixture('events/ee_event_without_identifiers.yml') }
  let_it_be(:event3_filepath) { 'config/events/internal_events_cli_closed.yml' }
  let_it_be(:event3_content) { internal_event_fixture('events/secondary_event_with_identifiers.yml') }

  describe 'end-to-end behavior' do
    YAML.safe_load(File.read('spec/fixtures/scripts/internal_events/metric_definer_examples.yml')).each do |test_case|
      it_behaves_like 'creates the right definition files', test_case['description'], test_case
    end
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
        "aggregate metric description\n" # Submit description
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
        "aggregate metric description\n" # Submit description
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
      ‣ Monthly/Weekly count of unique users who triggered internal_events_cli_used
        Monthly/Weekly count of unique projects where internal_events_cli_used occurred
        Monthly/Weekly count of unique namespaces where internal_events_cli_used occurred
        Monthly/Weekly/Total count of internal_events_cli_used occurrences
      TEXT

      with_cli_thread do
        expect { plain_last_lines(4) }.to eventually_equal_cli_text(expected_output)
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
        ‣ Monthly count of unique users who triggered internal_events_cli_used
          Monthly/Weekly count of unique projects where internal_events_cli_used occurred
          Monthly/Weekly count of unique namespaces where internal_events_cli_used occurred
          Monthly/Weekly/Total count of internal_events_cli_used occurrences
        ✘ Weekly count of unique users who triggered internal_events_cli_used (already defined)
        TEXT

        with_cli_thread do
          expect { plain_last_lines(5) }.to eventually_equal_cli_text(expected_output)
        end
      end
    end

    context 'with an existing total/monthly/weekly metric' do
      before do
        File.write(
          'ee/config/metrics/counts_all/count_total_internal_events_cli_used.yml',
          File.read('spec/fixtures/scripts/internal_events/metrics/ee_total_single_event.yml')
        )
      end

      it 'filters whole metric options' do
        select_event_from_list

        expected_output = <<~TEXT.chomp
        ‣ Monthly/Weekly count of unique users who triggered internal_events_cli_used
          Monthly/Weekly count of unique projects where internal_events_cli_used occurred
          Monthly/Weekly count of unique namespaces where internal_events_cli_used occurred
        ✘ Monthly/Weekly/Total count of internal_events_cli_used occurrences (already defined)
        TEXT

        with_cli_thread do
          expect { plain_last_lines(4) }.to eventually_equal_cli_text(expected_output)
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
        'config/metrics/counts_all/' \
          'count_distinct_project_id_from_internal_events_cli_closed_and_internal_events_cli_used.yml',
        File.read('spec/fixtures/scripts/internal_events/metrics/project_id_multiple_events.yml')
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
      ‣ Monthly/Weekly count of unique users who triggered any of 2 events
        Monthly/Weekly count of unique namespaces where any of 2 events occurred
        Monthly/Weekly/Total count of any of 2 events occurrences
      ✘ Monthly/Weekly count of unique projects where any of 2 events occurred (already defined)
      TEXT

      with_cli_thread do
        expect { plain_last_lines(4) }.to eventually_equal_cli_text(expected_output)
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
      ‣ Monthly/Weekly/Total count of internal_events_cli_opened occurrences
      ✘ Monthly/Weekly count of unique users who triggered internal_events_cli_opened (user unavailable)
      ✘ Monthly/Weekly count of unique projects where internal_events_cli_opened occurred (project unavailable)
      ✘ Monthly/Weekly count of unique namespaces where internal_events_cli_opened occurred (namespace unavailable)
      TEXT

      with_cli_thread do
        expect { plain_last_lines(4) }.to eventually_equal_cli_text(expected_output)
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

  context 'when additional properties are present' do
    let(:event_path_with_add_props) { 'config/events/internal_events_cli_used.yml' }
    let(:event_content_with_add_props) { internal_event_fixture('events/event_with_all_additional_properties.yml') }

    before do
      File.write(event_path_with_add_props, File.read(event_content_with_add_props))
    end

    it 'offers metrics to filter by or count unique additional props' do
      queue_cli_inputs([
        "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
        "1\n", # Enum-select: Single event -- count occurrences of a specific event or user interaction
        'internal_events_cli_used', # Filters to this event
        "\n" # Select: config/events/internal_events_cli_used.yml
      ])

      expected_output = <<~TEXT.chomp
      ‣ Monthly/Weekly count of unique users who triggered internal_events_cli_used
        Monthly/Weekly count of unique projects where internal_events_cli_used occurred
        Monthly/Weekly count of unique namespaces where internal_events_cli_used occurred
        Monthly/Weekly count of unique users who triggered internal_events_cli_used where label/property/value is...
        Monthly/Weekly count of unique projects where internal_events_cli_used occurred where label/property/value is...
        Monthly/Weekly count of unique namespaces where internal_events_cli_used occurred where label/property/value is...
        Monthly/Weekly/Total count of internal_events_cli_used occurrences
        Monthly/Weekly/Total count of internal_events_cli_used occurrences where label/property/value is...
        Monthly/Weekly count of unique values for 'label' from internal_events_cli_used occurrences
        Monthly/Weekly count of unique values for 'property' from internal_events_cli_used occurrences
        Monthly/Weekly count of unique values for 'value' from internal_events_cli_used occurrences
        Monthly/Weekly count of unique values for 'label' from internal_events_cli_used occurrences where property/value is...
        Monthly/Weekly count of unique values for 'property' from internal_events_cli_used occurrences where label/value is...
        Monthly/Weekly count of unique values for 'value' from internal_events_cli_used occurrences where label/property is...
      TEXT

      with_cli_thread do
        expect { plain_last_lines(14) }.to eventually_equal_cli_text(expected_output)
      end
    end

    context 'with multiple events' do
      let(:another_event_path) { 'config/events/internal_events_cli_opened.yml' }
      let(:another_event_content) { internal_event_fixture('events/secondary_event_with_additional_properties.yml') }

      before do
        File.write(another_event_path, File.read(another_event_content))
      end

      it 'disables unique metrics without shared additional props, but allows filtered metrics' do
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
          "2\n", # Enum-select: Single event -- count occurrences of a specific event or user interaction
          "internal_events_cli_", # Filters to this event
          " ", # Select: config/events/internal_events_cli_used.yml
          "\e[B ", # Arrow down & Select: config/events/internal_events_cli_opened.yml
          "\n" # Submit Multi-select
        ])

        # Note the disabled "property" field is deduplicated with the filtered option
        # The event only has label/value defined, so we'll include those
        expected_output = <<~TEXT.chomp
        ‣ Monthly/Weekly count of unique users who triggered any of 2 events
          Monthly/Weekly count of unique projects where any of 2 events occurred
          Monthly/Weekly count of unique namespaces where any of 2 events occurred
          Monthly/Weekly count of unique users who triggered any of 2 events where label/value/property is...
          Monthly/Weekly count of unique projects where any of 2 events occurred where label/value/property is...
          Monthly/Weekly count of unique namespaces where any of 2 events occurred where label/value/property is...
          Monthly/Weekly/Total count of any of 2 events occurrences
          Monthly/Weekly/Total count of any of 2 events occurrences where label/value/property is...
          Monthly/Weekly count of unique values for 'label' from any of 2 events occurrences
          Monthly/Weekly count of unique values for 'value' from any of 2 events occurrences
          Monthly/Weekly count of unique values for 'label' from any of 2 events occurrences where value/property is...
          Monthly/Weekly count of unique values for 'value' from any of 2 events occurrences where label/property is...
        ✘ Monthly/Weekly count of unique values for 'property' from any of 2 events occurrences (property unavailable)
        TEXT

        with_cli_thread do
          expect { plain_last_lines(13) }.to eventually_equal_cli_text(expected_output)
        end
      end

      it 'skips filter inputs for an unavailable property' do
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric -- calculate how often one or more existing events occur over time
          "2\n", # Enum-select: Multiple events -- count occurrences of a specific event or user interaction
          "internal_events_cli_", # Filters to this event
          " ", # Select: config/events/internal_events_cli_used.yml
          "\e[B ", # Arrow down & Select: config/events/internal_events_cli_opened.yml
          "\n", # Submit Multi-select
          "\e[A\n", # Arrow up & select Monthly/Weekly unique 'value' from any of 2 events where label/property is...
          "a label value\n", # Enter a value for 'label' for internal_events_cli_opened
          "\n", # Accept the same 'label' value for internal_events_cli_used
          "a property value\n", # Enter a value for 'property' for internal_events_cli_used
          "here's a description\n", # Submit a description
          "heres_a_key\n" # Submit a replacement key path for filtered metric
        ])

        # 'value' is an additional property for the metric here,
        # so proceeding to the next step without that extra input means we filtered
        with_cli_thread do
          expect { plain_last_lines }.to eventually_include_cli_text(
            'internal_events_cli_opened(label=a label value)',
            'internal_events_cli_used(label=a label value property=a property value)'
          )
        end
      end
    end
  end

  context 'when succeeded in saving the file' do
    let(:events) do
      [{
        action: 'internal_events_cli_closed', internal_events: true, product_group: 'optimize', tiers: ['ultimate']
      }, {
        action: 'internal_events_cli_used', internal_events: true, product_group: 'optimize', tiers: ['ultimate']
      }]
    end

    before do
      events.each do |event|
        File.write("config/events/#{event[:action]}.yml", event.transform_keys(&:to_s).to_yaml)
      end
    end

    context "when creating a single metric" do
      let(:metrics) do
        [
          { events: events.map { |e| { 'name' => e[:action] } }, time_frame: '7d' },
          { events: events.map { |e| { 'name' => e[:action] } }, time_frame: '28d' }
        ]
      end

      before do
        metrics.each do |metric|
          File.write(
            "config/metrics/counts_#{metric[:time_frame]}/count_total_cli_events_#{metric[:time_frame]}.yml",
            metric.transform_keys(&:to_s).to_yaml
          )
        end
      end

      it 'shows link to the metric dashboard' do
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric   -- calculate how often one or more existing events occur over time
          "2\n", # Enum-select: Multiple events -- count occurrences of several separate events or interactions
          'internal_events_cli', # Filters to the relevant events
          ' ', # Multi-select: internal_events_cli_closed
          "\e[B", # Arrow down to: internal_events_cli_used
          ' ', # Multi-select: internal_events_cli_used
          "\n", # Submit selections
          "\n", # Select: Monthly/Weekly/Total count
          "where a definition file was created with the CLI\n", # Input description
          "1\n", # Select: Copy & continue
          "\e[B \n", # Skip product categories
          "y\n" # Create file
        ])

        expected_output = <<~TEXT.chomp
        - Metric trend dashboard: https://10az.online.tableau.com/#/site/gitlab/views/PDServicePingExplorationDashboard/MetricTrend?Metrics%20Path=counts.count_total_internal_events_cli_closed_and_internal_events_cli_used
        TEXT

        with_cli_thread do
          expect { plain_last_lines }.to eventually_include_cli_text(expected_output)
        end
      end
    end

    context "when creating a multiple metrics" do
      it 'shows link to the metric dashboard' do
        queue_cli_inputs([
          "2\n", # Enum-select: New Metric   -- calculate how often one or more existing events occur over time
          "2\n", # Enum-select: Multiple events -- count occurrences of several separate events or interactions
          'internal_events_cli', # Filters to the relevant events
          ' ', # Multi-select: internal_events_cli_closed
          "\e[B", # Arrow down to: internal_events_cli_used
          ' ', # Multi-select: internal_events_cli_used
          "\n", # Submit selections
          "\n", # Select: Weekly/Monthly count
          "where a definition file was created with the CLI\n", # Input description
          "1\n", # Select: Copy & continue
          "\e[B \n", # Skip product categories
          "y\n" # Create file
        ])

        expected_output = <<-TEXT.chomp # <<- used instead of <<~ to save indentation
      - Metric trend dashboards:
        - https://10az.online.tableau.com/#/site/gitlab/views/PDServicePingExplorationDashboard/MetricTrend?Metrics%20Path=counts.count_total_internal_events_cli_closed_and_internal_events_cli_used_monthly
        - https://10az.online.tableau.com/#/site/gitlab/views/PDServicePingExplorationDashboard/MetricTrend?Metrics%20Path=counts.count_total_internal_events_cli_closed_and_internal_events_cli_used_weekly
        TEXT

        with_cli_thread do
          expect { plain_last_lines }.to eventually_include_cli_text(expected_output)
        end
      end
    end
  end
end
