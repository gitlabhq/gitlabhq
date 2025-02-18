# frozen_string_literal: true

require 'spec_helper'
require 'tty/prompt/test'
require_relative '../../../../../scripts/internal_events/cli'

RSpec.describe 'InternalEventsCli::Flows::UsageViewer', :aggregate_failures, feature_category: :service_ping do
  include_context 'when running the Internal Events Cli'

  let_it_be(:event1_filepath) { 'config/events/internal_events_cli_used.yml' }
  let_it_be(:event1_content) { internal_event_fixture('events/event_with_identifiers.yml') }
  let_it_be(:event2_filepath) { 'ee/config/events/internal_events_cli_opened.yml' }
  let_it_be(:event2_content) { internal_event_fixture('events/ee_event_without_identifiers.yml') }

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
        let(:category) { described_class.name }
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

  context 'for an event with multiple metrics' do
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
        let(:category) { described_class.name }
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
      ServicePingHelpers.get_current_usage_metric_value('redis_hll_counters.count_distinct_user_id_from_internal_events_cli_used_monthly')
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

      redis_hll_counters.count_distinct_user_id_from_internal_events_cli_used_monthly: https://10az.online.tableau.com/#/site/gitlab/views/PDServicePingExplorationDashboard/MetricTrend?Metrics%20Path=redis_hll_counters.count_distinct_user_id_from_internal_events_cli_used_monthly
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
        'config/metrics/counts_all/count_distinct_user_id_from_internal_events_cli_used.yml',
        File.read('spec/fixtures/scripts/internal_events/metrics/user_id_single_event.yml')
      )
    end

    it 'shows backend examples for all metrics' do
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
        let(:category) { described_class.name }
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
          value: 72, # Time the CLI ran before closing (seconds)
          custom_key: custom_value # The extra custom property name
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
        let(:category) { described_class.name }
        let(:project) { create(:project) }
        let(:user) { create(:user) }
        let(:additional_properties) do
          {
            label: 'string',
            value: 72,
            custom_key: custom_value
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
                custom_key: custom_value, // The extra custom property name
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
            custom_key: custom_value, // The extra custom property name
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
          data-event-custom_key=custom_value
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
          data-event-custom_key=custom_value
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

      .inline-block{ data: { event_tracking: 'internal_events_cli_used', event_label: 'string', event_value: 72, event_custom_key: custom_value } }
        = _('Important Text')

      --------------------------------------------------
      # HAML -- COMPONENT ON-CLICK

      = render Pajamas::ButtonComponent.new(button_options: { data: { event_tracking: 'internal_events_cli_used', event_label: 'string', event_value: 72, event_custom_key: custom_value } })

      --------------------------------------------------
      # HAML -- COMPONENT ON-LOAD

      = render Pajamas::ButtonComponent.new(button_options: { data: { event_tracking_load: true, event_tracking: 'internal_events_cli_used', event_label: 'string', event_value: 72, event_custom_key: custom_value } })

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
