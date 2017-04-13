class PoltergeistNetworkMonitor
  require 'pstore'
  require 'uri'
  require 'fileutils'

  def initialize(page)
    @page = page
  end

  def print_requests(longer_than_seconds:)
    return unless enabled?

    puts "\nNetwork:"
    puts Stats.new(requests).slower_than(longer_than_seconds)
    puts
  end

  def log_requests(path)
    return unless enabled?

    DataStore.new(path).store_requests(requests)
  end

  def self.log(page, debug: false)
    monitor = self.new(page)
    FileUtils.mkdir_p('tmp/capybara')
    if ENV['CI']
      path = "tmp/capybara/network_requests_#{ENV['CI_NODE_INDEX']}_#{ENV['CI_NODE_TOTAL']}.pstore"
      monitor.log_requests(path)
    else
      monitor.print_requests(longer_than_seconds: 0.1) if debug
      monitor.log_requests("tmp/capybara/network_requests.pstore")
    end
  end

  private

  attr_reader :page

  def enabled?
    Capybara.current_driver == :poltergeist
  end

  def network_traffic
    @network_traffic ||= page.driver.network_traffic
  end

  def requests
    network_traffic.map { |request| TimedRequest.new(request) }
                   .reject(&:incomplete?)
  end

  class DataStore
    def initialize(path)
      @data_store = PStore.new(path)
    end

    def load_requests
      requests = []
      @data_store.transaction(true) do
        requests = @data_store[:requests]
      end
      requests
    end

    def print_stats
      Stats.new(load_requests).print_summary
    end

    def store_requests(timed_requests)
      @data_store.transaction do
        @data_store[:requests] ||= Array.new
        @data_store[:requests].push(*timed_requests)
      end
    end
  end

  class Stats
    def initialize(requests)
      @requests = requests
    end

    def slower_than(seconds)
      @requests.select { |timed_request| timed_request.seconds > seconds }
               .sort_by(&:seconds)
    end

    def print_summary(io = $stdout)
      io.puts "Total Time - Average Time -\t\t\t Endpoint"
      endpoints = @requests.group_by(&:endpoint).map do |endpoint, requests|
        StatsLine.new(endpoint, requests)
      end
      io.puts endpoints.sort_by(&:total_time).reverse
    end

    class StatsLine
      def initialize(endpoint, requests)
        @endpoint = endpoint
        @requests = requests
      end

      def total_time
        @requests.map(&:seconds).reduce(&:+)
      end

      def average_time
        total_time / @requests.count.to_f
      end

      def to_s
        "#{Duration.new(total_time)} - #{Duration.new(average_time)} - #{@endpoint}"
      end
    end
  end

  class TimedRequest
    attr_reader :url, :method

    def initialize(request)
      # Avoid storing large request object by using it immediately
      # This reduces the space required to store this object during serialization
      @method = request.method
      @url = request.url
      @start_time = request.time
      @end_time = request.response_parts.first&.time
    end

    def host
      uri.host
    end

    def duration
      Duration.between(@start_time, @end_time)
    end

    def seconds
      duration.seconds
    end

    def incomplete?
      !@end_time
    end

    def endpoint
      sprintf("%-4s %s", method, normalized_url)
    end

    def to_s
      sprintf("%-4s %6s - %s", method, duration, normalized_url)
    end

    private

    def uri
      URI.parse(url)
    end

    def normalized_url
      "#{uri.host}#{normalized_path}"
    end

    # Replace numbered url segments so similar paths can be grouped
    def normalized_path
      uri.path.gsub(/\d+/, '$')
    end
  end

  class Duration
    attr_reader :seconds

    def initialize(seconds)
      @seconds = seconds
    end

    def self.between(start_time, end_time)
      self.new(end_time - start_time)
    end

    def to_s
      if seconds >= 1.0
        sprintf("%.4ss", seconds)
      else
        "#{milliseconds}ms"
      end
    end

    private

    def milliseconds
      (seconds * 1000).to_i
    end
  end
end

if defined?(RSpec)
  RSpec.configure do |config|
    config.after(type: :feature) do
      PoltergeistNetworkMonitor.log(page)
    end
  end
end

if defined?(Spinach)
  Spinach.hooks.after_scenario do |scenario_data, step_definitions|
    PoltergeistNetworkMonitor.log(Capybara.current_session)
  end
end
