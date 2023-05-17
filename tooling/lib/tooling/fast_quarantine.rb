# frozen_string_literal: true

module Tooling
  class FastQuarantine
    def initialize(fast_quarantine_path:)
      warn "#{fast_quarantine_path} doesn't exist!" unless File.exist?(fast_quarantine_path.to_s)

      @fast_quarantine_path = fast_quarantine_path
    end

    def identifiers
      @identifiers ||= begin
        quarantined_entity_identifiers = File.read(fast_quarantine_path).lines
        quarantined_entity_identifiers.compact!
        quarantined_entity_identifiers.map! do |quarantined_entity_identifier|
          quarantined_entity_identifier.delete_prefix('./').strip
        end
      rescue => e # rubocop:disable Style/RescueStandardError
        $stdout.puts e
        []
      end
    end

    def skip_example?(example)
      identifiers.find do |quarantined_entity_identifier|
        case quarantined_entity_identifier
        when /^.+_spec\.rb\[[\d:]+\]$/ # example id, e.g. spec/tasks/gitlab/usage_data_rake_spec.rb[1:5:2:1]
          example.id == "./#{quarantined_entity_identifier}"
        when /^.+_spec\.rb:\d+$/ # file + line, e.g. spec/tasks/gitlab/usage_data_rake_spec.rb:42
          fetch_metadata_from_ancestors(example, :location)
            .any?("./#{quarantined_entity_identifier}")
        when /^.+_spec\.rb$/ # whole file, e.g. ee/spec/features/boards/swimlanes/epics_swimlanes_sidebar_spec.rb
          fetch_metadata_from_ancestors(example, :file_path)
            .any?("./#{quarantined_entity_identifier}")
        end
      end
    end

    private

    attr_reader :fast_quarantine_path

    def fetch_metadata_from_ancestors(example, attribute)
      metadata = [example.metadata[attribute]]
      example_group = example.metadata[:example_group]

      loop do
        break if example_group.nil?

        metadata << example_group[attribute]
        example_group = example_group[:parent_example_group]
      end

      metadata
    end
  end
end
