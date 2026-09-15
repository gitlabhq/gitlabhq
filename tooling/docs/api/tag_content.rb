# frozen_string_literal: true

require 'yaml'

module Docs
  module Api
    class TagContent
      TAGS_DIR = File.expand_path('tags', __dir__)
      FRONT_MATTER_PATTERN = /\A---[ \t]*\R(?<front_matter>.*?)\R---[ \t]*(?:\R|\z)/m
      EXTENSION_PREFIX = 'x-'
      DOCS_URL = 'https://docs.gitlab.com'
      # Matches a markdown link that points to a relative path to a page under the
      # repository's doc/ directory. Captures the path below doc/ and any anchor.
      DOC_LINK_PATTERN = %r{\]\((?:\.\./)+doc/(?<path>[^)#]+)\.md(?<anchor>#[^)]*)?\)}
      # A page named _index is its directory's index page, and the docs site serves it at
      # the directory's URL, so we drop the _index suffix when building the absolute link.
      INDEX_PAGE_PATTERN = %r{(?:\A|/)_index\z}

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
          'description' => presence(absolute_links(body)),
          'x-displayName' => presence(front_matter['name']),
          'externalDocs' => external_docs(front_matter)
        }.merge(extensions(front_matter)).compact
      end

      # Docs links are written as relative paths so lychee can validate them offline,
      # which is much faster and more reliable than checking them over the network. We
      # convert them to absolute URLs here since the generated spec is served outside the docs site.
      def absolute_links(body)
        body.gsub(DOC_LINK_PATTERN) do
          match = Regexp.last_match

          "](#{docs_url_for(match[:path])}#{match[:anchor]})"
        end
      end

      def docs_url_for(path)
        page = path.sub(INDEX_PAGE_PATTERN, '')

        page.empty? ? "#{DOCS_URL}/" : "#{DOCS_URL}/#{page}/"
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
