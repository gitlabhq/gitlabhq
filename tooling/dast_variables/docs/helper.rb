# frozen_string_literal: true

require 'gitlab/utils/strong_memoize'

module Tooling
  module DastVariables
    module Docs
      module Helper
        TABLE_HEADER = <<~MD
          | CI/CD variable | Type | Example | Description |
          | :------------- | :--- | ------- | :---------- |
        MD

        def render_variables_table(filter)
          case filter
          when 'site'
            variables = Gitlab::Security::DastVariables.data[:site].filter { |_, variable| !variable[:auth] }
          when 'scanner'
            variables = Gitlab::Security::DastVariables.data[:scanner].filter { |_, variable| !variable[:auth] }
          when 'auth'
            variables = Gitlab::Security::DastVariables.auth_variables
          end

          rendered_variables = variables.map { |key, variable| render_variable(key, variable) }.join("\n")

          "#{TABLE_HEADER}#{rendered_variables}\n"
        end

        def render_variable(key, variable)
          render_row(
            "`#{key}`",
            render_type(variable[:type]),
            "`#{variable[:example]}`",
            render_description(variable[:description])
          )
        end

        def render_type(type)
          case type
          when 'Duration string' then '[Duration string](https://pkg.go.dev/time#ParseDuration)'
          when 'selector' then '[selector](authentication.md#finding-an-elements-selector)'
          else type
          end
        end

        def render_description(description)
          # replace help_page_path-generated documentation link
          # with relative path to documentation file
          description.sub(
            Gitlab::Security::DastVariables.ci_variables_documentation_link,
            '../../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui'
          )
        end

        def render_row(*values)
          "| #{values.map { |val| val.to_s.squish }.join(' | ')} |"
        end
      end
    end
  end
end
