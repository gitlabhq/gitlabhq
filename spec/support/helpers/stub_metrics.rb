# frozen_string_literal: true

module StubMetrics
  def authentication_metrics
    Gitlab::Auth::Activity
  end

  def stub_authentication_activity_metrics(debug: false)
    authentication_metrics.each_counter do |name, metric, description|
      allow(authentication_metrics).to receive(name)
        .and_return(double("#{metric} - #{description}"))
    end

    yield authentication_metrics if block_given?

    debug_authentication_activity_metrics if debug
  end

  def debug_authentication_activity_metrics
    authentication_metrics.tap do |metrics|
      metrics.each_counter do |name, metric|
        "#{name}_increment!".tap do |incrementer|
          allow(metrics).to receive(incrementer).and_wrap_original do |method|
            puts "Authentication activity metric incremented: #{name}"
            method.call
          end
        end
      end
    end
  end
end
