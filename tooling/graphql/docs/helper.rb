# frozen_string_literal: true

module Tooling
  module Graphql
    module Docs
      module Helper
        DEPRECATED_ICON = '{{< icon name="warning" >}}'
        EXPERIMENT_ICON = '{{< icon name="work-item-test-case" >}}'

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
          return "`#{item.type_signature}`" if item.type.is_a?(Schema::TempUndocumented)

          "[`#{item.type_signature}`](#{docs_link(item.type)})"
        end

        def default_arg_value(argument)
          return unless argument.default_value?

          "`#{argument.default_value}`"
        end

        def docs_render(partial, **args)
          template = "shared/#{partial}"
          Renderer.new(template: template, locals: args).execute
        end

        private

        def docs_link(item)
          page = item.class.name.demodulize.underscore.pluralize

          "#{page}.md##{item.name.downcase}"
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
