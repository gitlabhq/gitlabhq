# frozen_string_literal: true

# Helpers for calculating the latest metric values from specs and the dev rails console.
# The time frame for the metrics is modified to includes all records and events
# created on the current date (rather than only completed days from the last week.)
module ServicePingHelpers
  # Override metric timeframe from within specs
  # rubocop:disable RSpec/AnyInstanceOf -- Gitlab::Usage::TimeFrame is initialized multiple times from many classes
  def stub_metric_timeframes
    [
      :weekly_time_range,
      :monthly_time_range,
      :weekly_time_range_db_params,
      :monthly_time_range_db_params
    ].each do |method|
      allow_any_instance_of(Gitlab::Usage::TimeFrame)
        .to receive(method)
        .and_wrap_original { |_, **args| ClassWithStubbedTimeframe.new.send(method, **args) }
    end
  end
  # rubocop:enable RSpec/AnyInstanceOf

  class << self
    # Generates a full service ping report from rails console
    def get_current_service_ping_payload
      override_timeframe_from_dev_console!

      Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values)
    end

    # Reads the current value for a metric from rails console
    # @metric_key_path [String] key_path field from metric definition yml
    #     ex) 'usage_activity_by_stage_monthly.manage.issue_imports.csv'
    def get_current_usage_metric_value(metric_key_path)
      override_timeframe_from_dev_console!

      metric_definition = Gitlab::Usage::MetricDefinition.definitions[metric_key_path]

      raise ArgumentError, "Metric not found for key path #{metric_key_path}" unless metric_definition

      unless metric_definition.instrumentation_class
        raise ArgumentError,
          "Can't read metric value!\n  " \
          "This legacy metric is only available from the full service ping report. \n  " \
          "You can generate the report & read the value like this:\n\n  " \
          "ServicePingHelpers.get_current_service_ping_payload.dig(*'#{metric_key_path}'.split('.'))\n"
      end

      Gitlab::Usage::Metric.new(metric_definition).send(:instrumentation_object).value
    end

    private

    def override_timeframe_from_dev_console!
      if Rails.env.test?
        raise 'Prefer ServicePingHelpers#stub_metric_timeframe from specs!'
      elsif !defined?(Rails::Console) || !Rails.env.development?
        raise 'ServicePingHelpers override the timeframe used to calculate metrics. ' \
              'Use only in the development rails console.'
      end

      Gitlab::Usage::TimeFrame.prepend(ServicePingHelpers::CurrentTimeFrame)
    end
  end

  module CurrentTimeFrame
    def weekly_time_range
      super.merge(end_date: 1.week.from_now.to_date)
    end

    def monthly_time_range
      super.merge(end_date: 1.week.from_now.to_date)
    end

    def monthly_time_range_db_params(column: nil)
      super.transform_values { 30.days.ago..1.week.from_now }
    end

    def weekly_time_range_db_params(column: nil)
      super.transform_values { 9.days.ago..1.week.from_now }
    end
  end

  class ClassWithStubbedTimeframe
    include Gitlab::Usage::TimeFrame.dup
    include ::ServicePingHelpers::CurrentTimeFrame
  end
end
