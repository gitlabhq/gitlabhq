# frozen_string_literal: true

module Tooling
  module Graphql
    module Docs
      module Helper
        DEPRECATED_ICON = '{{< icon name="warning" >}}'
        EXPERIMENT_ICON = '{{< icon name="work-item-test-case" >}}'

        # The fields present on every connection object. Excluded from the
        # per-connection fields tables because they are documented once in the
        # connections section.
        STANDARD_CONNECTION_FIELDS = %w[edges nodes pageInfo].freeze

        def sorted_by_name(collection)
          collection.sort_by(&:name)
        end

        def name(item)
          "`#{item.name}`"
        end

        def description(item)
          description =
            if deprecated?(item)
              deprecation_description(item)
            elsif experiment?(item)
              experiment_description(item)
            else
              plain_description(item)
            end

          [description, doc_reference(item)].reject(&:empty?).join(' ')
        end

        def type(item)
          "[`#{item.type_signature}`](#{docs_link(item.type)})"
        end

        # A linked reference to a schema item, in the form [`Name`](page.md#name).
        def item_link(item)
          "[`#{item.name}`](#{docs_link(item)})"
        end

        def default_arg_value(argument)
          return unless argument.default_value?

          "`#{argument.default_value}`"
        end

        def connection_note
          "This field is a [connection](#{connections_link}) and accepts the " \
            'four standard pagination arguments: `before`, `after`, `first`, `last`.'
        end

        # Renders the full body for an object section (below the ## heading).
        # Handles connection and ordinary object layouts.
        def render_object_body(type)
          parts = type.connection? ? connection_body_parts(type) : object_body_parts(type)
          "#{parts.join("\n\n")}\n"
        end

        # Renders the full body for an interface section (below the ## heading).
        def render_interface_body(interface)
          "#{interface_body_parts(interface).join("\n\n")}\n"
        end

        # Renders the full body for a union section (below the ## heading).
        def render_union_body(union)
          "#{union_body_parts(union).join("\n\n")}\n"
        end

        # Renders the full body for a query section (below the ## heading).
        def render_query_body(query)
          "#{query_body_parts(query).join("\n\n")}\n"
        end

        # Summary for a connection object, linking to the node type and the
        # standard connection fields section. A node without a resolvable type
        # (such as a subclassed connection) is rendered unlinked.
        def connection_summary(object)
          node = object.node_type
          node_link = node ? item_link(node) : '``'

          "Paginated collection of #{node_link}. " \
            "See [Standard connection fields](#standard-connection-fields) " \
            "for the fields available on every connection."
        end

        # Fields on a connection object that go beyond the standard set
        # (edges, nodes, pageInfo).
        def extra_connection_fields(object)
          object.fields.reject { |f| STANDARD_CONNECTION_FIELDS.include?(f.name) }
        end

        def field_description(field)
          description = description(field)
          return description unless field.connection?

          [description, connection_note].reject(&:empty?).join(' ')
        end

        # Whether a field has documentable arguments, excluding the standard
        # pagination arguments that are documented in the connections section.
        def documented_arguments?(field)
          field.arguments_without_pagination.present?
        end

        def docs_render(partial, **args)
          template = "shared/#{partial}"
          Renderer.new(template: template, locals: args.merge(page: current_page)).execute
        end

        private

        def current_page
          @page
        end

        def connection_body_parts(type)
          parts = [connection_summary(type)]
          extra = extra_connection_fields(type)

          if extra.present?
            parts << "### Extra fields {.no_toc}\n\n" \
              "This connection has additional fields beyond the " \
              "[standard connection fields](#standard-connection-fields).\n\n" \
              "#{docs_render('fields_table', fields: extra)}"
          end

          parts
        end

        def object_body_parts(type)
          parts = []
          desc = description(type)
          parts << desc if desc.present?

          interfaces = type.implemented_interfaces

          if interfaces.present?
            links = interfaces.map { |interface| item_link(interface) }.join(', ')
            parts << "**Implements:** #{links}"
          end

          parts << "### Fields {.no_toc}\n\n#{docs_render('fields_table', fields: type.fields)}"
          parts
        end

        def interface_body_parts(interface)
          parts = []
          desc = description(interface)
          parts << desc if desc.present?

          implementations = interface.implementations

          if implementations.present?
            links = implementations.map { |implementation| "- #{item_link(implementation)}" }
            parts << "### Implementations {.no_toc}\n\n#{links.join("\n")}"
          end

          parts << "### Fields {.no_toc}\n\n#{docs_render('fields_table', fields: interface.fields)}"
          parts
        end

        def union_body_parts(union)
          parts = []
          desc = description(union)
          parts << desc if desc.present?

          members = union.members

          if members.present?
            links = members.map { |member| "- #{item_link(member)}" }
            parts << "### Member types {.no_toc}\n\n#{links.join("\n")}"
          end

          parts
        end

        def query_body_parts(query)
          parts = []
          desc = field_description(query)
          parts << desc if desc.present?
          parts << "**Returns:** #{type(query)}"

          if documented_arguments?(query)
            parts << "### Arguments {.no_toc}\n\n" \
              "#{docs_render('arguments_table', arguments: query.arguments_without_pagination)}"
          end

          parts
        end

        # Anchor for the connections section, which lives on the objects page.
        # Same-page links can be bare anchors.
        def connections_link
          anchor = '#connections-and-pagination'
          return anchor if current_page == 'objects.md'

          "objects.md#{anchor}"
        end

        def docs_link(item)
          page = "#{item.class.name.demodulize.underscore.pluralize}.md"
          anchor = "##{item.name.downcase}"

          # Link within the same page can be a bare anchor.
          return anchor if page == current_page

          "#{page}#{anchor}"
        end

        def plain_description(item)
          description = item.description&.strip
          return '' unless description

          # Some object type descriptions do not end in `.` yet.
          description = "#{description}." unless description.end_with?('.')
          description
        end

        # Renders the `see:` documentation references as `See [title](url).`
        def doc_reference(item)
          references = item.try(:doc_reference)
          return '' if references.blank?

          links = references.map { |title, url| "[#{title.strip}](#{url.strip})" }

          "See #{links.join(', ')}."
        end

        def experiment?(item)
          item.is_a?(Schema::Deprecable) && item.experiment?
        end

        def deprecated?(item)
          item.is_a?(Schema::Deprecable) && item.deprecated?
        end

        def deprecation_description(item)
          string = "Deprecated in GitLab #{item.deprecation.milestone}. " \
            "#{item.deprecation.reason_text}"
          string = "#{string} Use `#{item.deprecation.replacement}` instead." if item.deprecation.replacement
          string
        end

        def experiment_description(item)
          "Status: Experiment. Introduced in GitLab #{item.deprecation.milestone}." \
            "<br/><br/>#{item.deprecation.original_description}"
        end
      end
    end
  end
end
