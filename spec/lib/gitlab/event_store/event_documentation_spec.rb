# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../tooling/docs/event_nodoc'

RSpec.describe 'Event store documentation', feature_category: :tooling do
  let(:ce_events_dir) { Rails.root.join('app/events') }
  let(:ee_events_dir) { Rails.root.join('ee/app/events') }
  let(:all_docs) do
    all_doc_files.map do |f|
      YAML.safe_load_file(f).merge('_file' => f)
    end
  end

  let(:docs_dir) { Rails.root.join('data/events') }
  let(:feature_categories) { YAML.safe_load_file(Rails.root.join('config/feature_categories.yml')) }

  let(:all_event_files) do
    files = Dir[ce_events_dir.join('**/*.rb')] + Dir[ee_events_dir.join('**/*.rb')]
    files.reject { |f| Docs::EventNodoc.excluded?(f, Rails.root) }
  end

  let(:all_doc_files) do
    Dir[docs_dir.join('**/*.yml')].reject { |f| f.include?('/templates/') }.sort
  end

  def doc_path_for(event_file)
    relative = event_file.sub(%r{^.+/app/events/}, '')
    docs_dir.join(relative.sub(/\.rb$/, '.yml')).to_s
  end

  def event_in_ee?(event_file)
    event_file.start_with?(ee_events_dir.to_s)
  end

  describe 'coverage' do
    it 'every event class has a documentation file' do
      missing = all_event_files.reject { |f| File.exist?(doc_path_for(f)) }

      expect(missing).to be_empty,
        "Missing event documentation. Run `scripts/generate_event_doc <path>` or " \
          "copy data/events/templates/example.yml:\n" \
        + missing.map { |f| "  #{doc_path_for(f)}" }.join("\n") + "\n" \
          "Then run `bin/rake gitlab:docs:compile_events`."
    end

    it 'no two source files map to the same documentation path' do
      collisions = all_event_files.group_by { |f| doc_path_for(f) }.select { |_, sources| sources.size > 1 }

      message = collisions.map do |doc, sources|
        "#{doc} is targeted by multiple sources: #{sources.join(', ')}"
      end.join("\n")

      expect(collisions).to be_empty, message
    end

    it 'every documentation file references an existing event class' do
      violations = all_docs.filter_map do |doc|
        class_name = doc['event']
        next "#{doc['_file']}: missing 'event' key" if class_name.blank?
        # FOSS builds strip the ee/ directory; ee_only classes are unloadable there.
        next if doc['ee_only'] && !File.directory?(ee_events_dir)

        begin
          class_name.constantize
          nil
        rescue NameError
          "#{doc['_file']}: '#{class_name}' is not a loadable Ruby class"
        end
      end

      expect(violations).to be_empty, violations.join("\n")
    end
  end

  describe 'schema' do
    it 'every documentation file has all required keys' do
      required_keys = %w[event description feature_category]

      violations = all_docs.flat_map do |doc|
        missing = required_keys - doc.keys
        missing.map { |k| "#{doc['_file']}: missing required key '#{k}'" }
      end

      expect(violations).to be_empty, violations.join("\n")
    end

    it 'every feature_category is in the canonical list' do
      violations = all_docs.filter_map do |doc|
        category = doc['feature_category']
        next if feature_categories.include?(category)

        "#{doc['_file']}: '#{category}' is not a known feature_category"
      end

      expect(violations).to be_empty, violations.join("\n")
    end

    it 'ee_only matches the source path of the event class' do
      violations = all_event_files.filter_map do |event_file|
        doc_file = doc_path_for(event_file)
        next unless File.exist?(doc_file)

        declared = YAML.safe_load_file(doc_file)['ee_only'] == true

        if event_in_ee?(event_file) && !declared
          "#{doc_file}: must declare `ee_only: true` (source is under ee/app/events/)"
        elsif !event_in_ee?(event_file) && declared
          "#{doc_file}: must not declare `ee_only: true` (source is under app/events/)"
        end
      end

      expect(violations).to be_empty, violations.join("\n")
    end
  end
end
