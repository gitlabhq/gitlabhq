module StubMetrics
  def authentication_metrics
    Gitlab::Auth::Activity
  end

  def stub_authentication_activity_metrics(debug: false)
    authentication_metrics.each_counter do |name, metric, description|
      double("#{metric} - #{description}").tap do |counter|
        allow(counter).to receive(:increment) do
          puts "Authentication activity metric incremented: #{metric}"
        end

        allow(authentication_metrics).to receive(name).and_return(counter)
      end
    end
  end
end
