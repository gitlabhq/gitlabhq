begin
  class Knapsack::Report
    alias_method :save_without_leading_existing_report, :save

    def load_existing_report
      Knapsack::Presenter.existing_report = open
    rescue
      false
    end

    def save
      load_existing_report
      save_without_leading_existing_report
    end
  end

  class << Knapsack::Presenter
    attr_accessor :existing_report

    def initialize
      @existing_report = []
    end

    def report_hash
      return current_report_hash unless existing_report
      existing_report.merge(current_report_hash).sort.to_h
    end

    def current_report_hash
      Knapsack.tracker.test_files_with_time
    end

    def report_yml
      report_hash.to_yaml
    end

    def report_json
      JSON.pretty_generate(report_hash)
    end
  end
end
