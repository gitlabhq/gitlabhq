# frozen_string_literal: true

RSpec.shared_context 'when rendered view has no HTML escapes', type: :view do
  # Check once per example if `rendered` contains HTML escapes.
  let(:rendered) do |example|
    super().tap do |rendered|
      next if example.metadata[:skip_html_escaped_tags_check]

      ensure_no_html_escaped_tags!(rendered, example)
    end
  end

  def ensure_no_html_escaped_tags!(content, example)
    match_data = HtmlEscapedHelpers.match_html_escaped_tags(content)
    return unless match_data

    # Truncate
    pre_match = match_data.pre_match.last(50)
    match = match_data[0]
    post_match = match_data.post_match.first(50)

    string = "#{pre_match}«#{match}»#{post_match}"

    raise <<~MESSAGE
      The following string contains HTML escaped tags:

      #{string}

      Please consider using `.html_safe`.

      This check can be disabled via:

        it #{example.description.inspect}, :skip_html_escaped_tags_check do
          ...
        end

    MESSAGE
  end
end
