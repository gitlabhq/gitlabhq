# frozen_string_literal: true

require 'erb'

module Docs
  class EventHandling
    YAML_GLOB = Rails.root.join('data/events/**/*.yml').freeze
    TEMPLATE_PATH = Rails.root.join('data/events/templates/_event_template.md.erb').freeze

    def render
      entries = load_entries
      domains = entries.map { |e| e['domain'] }.uniq.sort # rubocop:disable Rails/Pluck -- not an AR relation

      load_template.result_with_hash(entries: entries, domains: domains)
    end

    private

    def load_entries
      Dir.glob(YAML_GLOB)
        .reject { |f| f.include?('/templates/') }
        .map { |file| load_entry(file) }
        .sort_by { |e| [e['domain'], e['event']] }
    end

    def load_entry(file)
      YAML.safe_load_file(file).merge('domain' => domain_for(file))
    rescue Psych::Exception => e
      raise "Failed to parse #{file}: #{e.message}"
    end

    def domain_for(file)
      file.delete_prefix(Rails.root.join('data/events/').to_s).split('/').first
    end

    def load_template
      ERB.new(File.read(TEMPLATE_PATH), trim_mode: '-')
    end
  end
end
