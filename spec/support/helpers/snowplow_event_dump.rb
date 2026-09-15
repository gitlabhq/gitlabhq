# frozen_string_literal: true

# Writes what a spec captured to `captured_snowplow_events/`, under a directory per spec file and
# per example. `index.json` at the root maps each dump to the tracking journey and variant it
# proves, for anyone fetching one without knowing the spec.
#
# Re-running an example replaces its directory, so what is on disk is always the last run. The
# header records when, since a directory left behind by an earlier run looks no different.
#
# Two files per example. The YAML is contract-shaped, so it can be trimmed into a new tracking
# journey or pasted into a rollout issue as evidence of the events an experiment emits. The JSON
# is the payloads exactly as they would have been POSTed, for when the wire format itself is the
# question.
#
# This records what the spec produced, against a stubbed assignment. It is not a substitute for
# checking the events against a real feature flag in a running GDK.
module SnowplowEventDump
  DIRECTORY = Rails.root.join(ENV['CI'] ? 'rspec/captured_snowplow_events' : 'tmp/captured_snowplow_events')

  # Event types a contract has no way to express, reported as a count so nothing looks lost.
  UNCONTRACTABLE = { 'pv' => 'page view', 'ue' => 'self-describing event' }.freeze

  class << self
    def write(example, captured:, raw:)
      structured, other = captured.partition { |event| event.event_type == 'se' }
      directory = directory_for(example)

      FileUtils.rm_rf(directory)
      FileUtils.mkdir_p(directory)

      directory.join('events.yml')
        .write([header(example, other), { 'events' => contract_entries(structured) }.to_yaml].join("\n"))
      directory.join('payloads.json').write(::Gitlab::Json.pretty_generate(raw))

      update_index(example, directory)
    end

    private

    def update_index(example, directory)
      relative = directory.relative_path_from(DIRECTORY)
      journey = example.metadata[:snowplow_tracking_journey] || {}

      entry = {
        'journey' => journey[:name],
        'variant' => journey[:variant],
        'example' => example.full_description,
        'location' => example.location,
        'events' => relative.join('events.yml').to_s,
        'payloads' => relative.join('payloads.json').to_s
      }

      path = DIRECTORY.join('index.json')
      kept = entries_in(path)
        .reject { |other| other['events'] == entry['events'] }
        .select { |other| DIRECTORY.join(other['events']).exist? }

      path.write(::Gitlab::Json.pretty_generate(kept << entry))
    end

    def entries_in(path)
      return [] unless path.exist?

      ::Gitlab::Json::SafeParser.parse(path.read)
    end

    # RSpec's example id, ./path/to/spec.rb[1:2:1], is the only identifier unique across both spec
    # files and examples. Descriptions are not, since a shared example carries the same one into
    # every context, and neither is the basename, which EE specs share with their FOSS counterpart.
    # index.json is what says which journey a directory holds.
    def directory_for(example)
      spec, scope = example.id.delete_prefix('./').delete_suffix(']').split('.rb[')

      DIRECTORY.join(spec, scope.tr(':', '-'))
    end

    def contract_entries(events)
      events.map do |event|
        { 'category' => event.category, 'action' => event.action,
          'label' => event.label, 'property' => event.property }.compact
      end.uniq
    end

    def header(example, other)
      lines = [
        "# Captured from: #{example.full_description}",
        "# #{example.location} at #{Time.current.utc.iso8601}",
        '#',
        '# Frontend categories are the page an event fired on, so they are rarely worth asserting.'
      ]

      counts = other.group_by(&:event_type).transform_values(&:count)

      return lines.join("\n") if counts.empty?

      described = counts.map { |type, count| "#{count} #{UNCONTRACTABLE.fetch(type, type).pluralize(count)}" }
      lines << "# Also captured, not expressible in a contract: #{described.join(', ')}"

      lines.join("\n")
    end
  end
end
