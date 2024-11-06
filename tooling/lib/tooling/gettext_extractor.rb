# frozen_string_literal: true

require 'parallel'
require 'gettext/po'
require 'gettext/po_entry'
require 'gettext/tools/xgettext'
require 'gettext/tools/parser/erb'
require 'gettext/tools/parser/ruby'
require 'json'
require 'open3'

module Tooling
  class GettextExtractor < GetText::Tools::XGetText
    class HamlParser < GetText::RubyParser
      require 'hamlit/engine'
      def parse_source(source)
        super(Hamlit::Engine.new.call(source))
      end
    end

    def initialize(
      backend_glob: "{ee/,}{app,lib,config,locale}/**/*.{rb,erb,haml}",
      glob_base: nil,
      package_name: 'gitlab',
      package_version: '1.0.0'
    )
      super()
      @backend_glob = backend_glob
      @package_name = package_name
      @glob_base = glob_base || Dir.pwd
      @package_version = package_version
      # Ensure that the messages are ordered by id
      @po_order = :msgid
      @po_format_options = {
        # No line breaks within a message
        max_line_width: -1,
        # Do not print references to files
        include_reference_comment: false
      }
    end

    def parse(_paths)
      po = GetText::PO.new
      parse_backend_files.each do |po_entry|
        merge_po_entries(po, po_entry)
      end
      parse_frontend_files.each do |po_entry|
        merge_po_entries(po, po_entry)
      end
      po
    end

    # Overrides method from GetText::Tools::XGetText
    # This makes a method public and passes in an empty array of paths,
    # as our overidden "parse" method needs no paths
    def generate_pot
      super([])
    end

    private

    # Overrides method from GetText::Tools::XGetText
    # in order to remove revision dates, as we check in our locale/gitlab.pot
    def header_content
      super.gsub(/^POT?-(?:Creation|Revision)-Date:.*\n/, '')
    end

    def merge_po_entries(po, po_entry)
      existing_entry = po[po_entry.msgctxt, po_entry.msgid]
      po_entry = existing_entry.merge(po_entry) if existing_entry

      po[po_entry.msgctxt, po_entry.msgid] = po_entry
    end

    def parse_backend_file(path)
      source = ::File.read(path).force_encoding("utf-8").encode("utf-8", replace: nil)
      # Do not bother parsing files not containing `_(`
      # All of our translation helpers, _(, s_(), N_(), etc.
      # contain it. So we can skip parsing files not containing it
      return [] unless source.include?('_(')

      case ::File.extname(path)
      when '.rb'
        GetText::RubyParser.new(path).parse_source(source)
      when '.haml'
        HamlParser.new(path).parse_source(source)
      when '.erb'
        GetText::ErbParser.new(path).parse
      else
        raise NotImplementedError
      end
    end

    def parse_backend_files
      files = Dir.glob(File.join(@glob_base, @backend_glob))
      Parallel.flat_map(files) { |item| parse_backend_file(item) }
    end

    def parse_frontend_files
      results, status = Open3.capture2('node scripts/frontend/extract_gettext_all.js --all')
      raise StandardError, "Could not parse frontend files" unless status.success?

      # rubocop:disable Gitlab/Json
      JSON.parse(results)
          .values
          .flatten(1)
          .collect { |entry| create_po_entry(*entry) }
      # rubocop:enable Gitlab/Json
    end
  end
end
