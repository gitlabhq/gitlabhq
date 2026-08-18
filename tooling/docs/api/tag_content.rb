# frozen_string_literal: true

require 'yaml'

module Docs
  module Api
    class TagContent
      TAGS_DIR = File.expand_path('tags', __dir__)
      FRONT_MATTER_PATTERN = /\A---[ \t]*\R(?<front_matter>.*?)\R---[ \t]*(?:\R|\z)/m
      EXTENSION_PREFIX = 'x-'

      attr_reader :tags_dir

      def initialize(tags_dir = TAGS_DIR)
        @tags_dir = tags_dir
      end

      def to_h
        @to_h ||= tag_files.to_h { |path| [slug_for(path), fields_for(File.read(path))] }
      end

      def [](slug)
        to_h[slug]
      end

      def slugs
        to_h.keys
      end

      def tag_files
        @tag_files ||= Dir.glob(File.join(tags_dir, '*.md'))
      end

      def slug_for(path)
        File.basename(path, '.md')
      end

      def front_matter_for(path)
        parse(File.read(path)).first
      end

      private

      def fields_for(raw)
        front_matter, body = parse(raw)

        {
          'description' => presence(body),
          'x-displayName' => presence(front_matter['name']),
          'externalDocs' => external_docs(front_matter)
        }.merge(extensions(front_matter)).compact
      end

      def parse(raw)
        match = FRONT_MATTER_PATTERN.match(raw)
        return [{}, raw] unless match

        [front_matter_hash(match[:front_matter]), match.post_match]
      end

      def front_matter_hash(raw_front_matter)
        parsed = YAML.safe_load(raw_front_matter)

        parsed.is_a?(Hash) ? parsed : {}
      rescue Psych::Exception
        {}
      end

      def external_docs(front_matter)
        url = presence(front_matter['external_docs'])

        { 'url' => url } if url
      end

      def extensions(front_matter)
        front_matter.select { |key, _| key.to_s.start_with?(EXTENSION_PREFIX) }
      end

      def presence(value)
        stripped = value.to_s.strip

        stripped unless stripped.empty?
      end
    end
  end
end
