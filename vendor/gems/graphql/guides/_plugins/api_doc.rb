# frozen_string_literal: true
require_relative "../../lib/graphql/version"
require "kramdown"

module GraphQLSite
  API_DOC_ROOT = "/api-doc/#{GraphQL::VERSION}/"

  module APIDoc
    def api_doc(input)
      if !input.start_with?("GraphQL")
        ruby_ident = "GraphQL::#{input}"
      else
        ruby_ident = input
      end

      doc_path = ruby_ident
        .gsub("::", "/")                        # namespaces
        .sub(/#(.+)$/, "#\\1-instance_method")  # instance methods
        .sub(/\.(.+)$/, "#\\1-class_method")    # class methods

      %|<a href="#{API_DOC_ROOT}#{doc_path}" target="_blank" title="API docs for #{ruby_ident}"><code>#{input}</code></a>|
    end

    def link_to_img(img_path, img_title)
      full_img_path = "#{@context.registers[:site].baseurl}#{img_path}"
      <<-HTML
<a href="#{full_img_path}" target="_blank" class="img-link">
  <img src="#{full_img_path}" title="#{img_title}" alt="#{img_title}" />
</a>
      HTML
    end
  end

  class APIDocRoot < Liquid::Tag
    def render(context)
      API_DOC_ROOT
    end
  end

  class CalloutBlock < Liquid::Block
    def initialize(tag_name, callout_class, tokens)
      super
      @callout_class = callout_class.strip
    end

    def render(context)
      raw_text = super

      site = context.registers[:site]
      converter = site.find_converter_instance(::Jekyll::Converters::Markdown)
      rendered_text = converter.convert(raw_text)

      heading = case @callout_class
      when "warning"
        "⚠ Heads up!"
      else
        raise ArgumentError, "Unhandled callout class: #{@callout_class.inspect}"
      end
      %|<div class="callout callout-#{@callout_class}"><p class="heading">#{heading}</p>#{rendered_text}</div>|
    end
  end

  class OpenAnIssue < Liquid::Tag
    def initialize(tag_name, issue_info, tokens)
      title, body = issue_info.split(",")
      # remove whitespace and quotes if value is present
      @title = strip_arg(title)
      @body = strip_arg(body)
    end

    def render(context)
      %|<a href="https://github.com/rmosolgo/graphql-ruby/issues/new?title=#{@title}#{@body ? "&body=#{@body}" : ""}" target="_blank">open an issue</a>|
    end

    private

    def strip_arg(text)
      text && text.strip[1..-2]
    end
  end

  # Build a URL relative to `site.baseurl`,
  # asserting that the page exists.
  class InternalLink < Liquid::Tag
    GUIDES_ROOT = "guides/"

    def initialize(tag_name, guide_info, tokens)
      text, path = guide_info.split(",")
      # remove whitespace and quotes if value is present
      @text = strip_arg(text)
      @path = strip_arg(path)
      if @path && @path.start_with?("/")
        @path = @path[1..-1]
      end
      if !exist?(@path)
        raise "Internal link failed, couldn't find file for: #{path}"
      end
    end

    def render(context)
      <<-HTML.chomp
<a href="#{context["site"]["baseurl"]}/#{@path}">#{@text}</a>
      HTML
    end

    private

    def strip_arg(text)
      text && text.strip[1..-2]
    end

    POSSIBLE_EXTENSIONS = [".html", ".md"]
    def exist?(path)
      filepath =  GUIDES_ROOT + path.split("#").first
      filepath = filepath.sub(".html", "")
      POSSIBLE_EXTENSIONS.any? { |ext| File.exist?(filepath + ext) }
    end
  end

  class TableOfContents < Liquid::Tag
    def render(context)
      headers = context["page"]["content"].scan(/^##+[^\n]+$/m)
      section_count = 0
      current_table = header_table = [nil]
      prev_depth = nil
      headers.each do |h|
        header_hashes = h.match(/^#+/)[0]
        depth = header_hashes.size
        if depth == 2
          section_count += 1
        end
        text = h.gsub(/^#+ /, "")
        target = text.downcase
          .gsub(/[^a-z0-9_]+/, "-")
          .sub(/-$/, "")
          .sub(/^-/, "")

        rendered_text = Kramdown::Document.new(text, auto_ids: false)
          .to_html
          .sub("<p>", "")
          .sub("</p>", "") # remove wrapping added by kramdown

        if prev_depth
          if prev_depth > depth
            # outdent
            current_table = current_table[0]
          elsif prev_depth < depth
            # indent
            new_table = [current_table]
            current_table[-1][-1] = new_table
            current_table = new_table
          else
            # same depth
          end
        end

        current_table << [rendered_text, target, []]
        prev_depth = depth
      end

      table_html = "".dup
      render_table_into_html(table_html, header_table)

      html = <<~HTML
      <div class="table-of-contents">
        <h3 class="contents-header">Contents</h3>
        #{table_html}
      </div>
      HTML

      if section_count == 0
        if headers.any?
          full_path = "guides/#{context["page"]["path"]}"
          warn("No sections identified for #{full_path} -- make sure it's using `## ...` for section headings.")
        end
        ""
      else
        html
      end
    end

    private

    def render_table_into_html(html_str, table)
      html_str << "<ol class='contents-list'>"
      table.each_with_index do |entry, idx|
        if idx == 0
          next # parent reference
        end
        rendered_text, target, child_table = *entry
        html_str << "<li class='contents-entry'>"
        html_str << "<a href='##{target}'>#{rendered_text}</a>"
        if child_table.any?
          render_table_into_html(html_str, child_table)
        end
        html_str << "</li>"
      end
      html_str << "</ol>"
    end
  end
end



Liquid::Template.register_filter(GraphQLSite::APIDoc)
Liquid::Template.register_tag("api_doc_root", GraphQLSite::APIDocRoot)
Liquid::Template.register_tag("open_an_issue", GraphQLSite::OpenAnIssue)
Liquid::Template.register_tag("internal_link", GraphQLSite::InternalLink)
Liquid::Template.register_tag("table_of_contents", GraphQLSite::TableOfContents)
Liquid::Template.register_tag('callout', GraphQLSite::CalloutBlock)
Jekyll::Hooks.register :site, :pre_render do |site|
  section_pages = Hash.new { |h, k| h[k] = [] }
  section_names = []
  site.pages.each do |page|
    this_section = page.data["section"]
    if this_section
      this_section_pages = section_pages[this_section]
      this_section_pages << page
      this_section_pages.sort_by! { |page| page.data["index"] || 100 }
      page.data["section_pages"] = this_section_pages
      section_names << this_section
    end
  end
  section_names.compact!
  section_names.uniq!
  all_sections = []
  section_names.each do |section_name|
    all_sections << {
      "name" => section_name,
      "overview_page" => section_pages[section_name].first,
    }
  end

  sorted_section_names = site.pages.find { |p| p.data["title"] == "Guides Index" }.data["sections"].map { |s| s["name"] }
  all_sections.sort_by! { |s| sorted_section_names.index(s["name"]) }
  site.data["all_sections"] = all_sections
end

module Jekyll
  module Algolia
    module Hooks
      def self.before_indexing_each(record, node, context)
        record = record.dup
        record.delete(:section_pages)
        record
      end
    end
  end
end
