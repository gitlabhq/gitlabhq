# frozen_string_literal: true

RSpec.shared_context 'when rendered has no HTML escapes' do
  # Check once per example if `rendered` contains HTML escapes.
  let(:rendered) do |example|
    super().tap do |rendered|
      next if example.metadata[:skip_html_escaped_tags_check]

      HtmlEscapedHelpers.ensure_no_html_escaped_tags!(rendered, example)
    end
  end
end

RSpec.shared_context 'when page has no HTML escapes' do
  # Check once per example if `page` contains HTML escapes.
  let(:page) do |example|
    super().tap do |page|
      next if example.metadata[:skip_html_escaped_tags_check]

      HtmlEscapedHelpers.ensure_no_html_escaped_tags!(page.native.to_s, example)
    end
  end
end
