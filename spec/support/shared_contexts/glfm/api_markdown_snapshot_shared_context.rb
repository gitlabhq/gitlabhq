# frozen_string_literal: true

require_relative '../../../../scripts/lib/glfm/constants'

# See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
# for documentation on this spec.
RSpec.shared_context 'with API::Markdown Snapshot shared context' do |ee_only: false|
  include_context 'with GLFM example snapshot fixtures'

  include ApiHelpers

  markdown_examples, html_examples, normalizations_by_example_name, metadata_by_example_name = [
    Glfm::Constants::ES_MARKDOWN_YML_PATH,
    Glfm::Constants::ES_HTML_YML_PATH,
    Glfm::Constants::GLFM_EXAMPLE_NORMALIZATIONS_YML_PATH,
    Glfm::Constants::GLFM_EXAMPLE_METADATA_YML_PATH
  ].map { |path| YAML.safe_load(File.open(path), symbolize_names: true, aliases: true) }

  if (focused_markdown_examples_string = ENV['FOCUSED_MARKDOWN_EXAMPLES'])
    focused_markdown_examples = focused_markdown_examples_string.split(',').map(&:strip).map(&:to_sym)
    markdown_examples.select! { |example_name| focused_markdown_examples.include?(example_name) }
  end

  markdown_examples.select! { |example_name| !!metadata_by_example_name&.dig(example_name, :ee) == ee_only }

  markdown_examples.each do |name, markdown|
    context "for #{name}" do
      let(:html) { html_examples.fetch(name).fetch(:static) }
      let(:normalizations) { normalizations_by_example_name.dig(name, :html, :static, :snapshot) }

      it "verifies conversion of GLFM to HTML", :unlimited_max_formatted_output_length do
        # noinspection RubyResolve
        normalized_html = normalize_html(html, normalizations)
        api_url = metadata_by_example_name&.dig(name, :api_request_override_path) || (api "/markdown")

        post api_url, params: { text: markdown, gfm: true }
        expect(response).to be_successful
        parsed_response = Gitlab::Json.parse(response.body, symbolize_names: true)
        # Some responses have the HTML in the `html` key, others in the `body` key.
        response_html = parsed_response[:body] || parsed_response[:html]
        normalized_response_html = normalize_html(response_html, normalizations)

        expect(normalized_response_html).to eq(normalized_html)
      end

      def normalize_html(html, normalizations)
        return html unless normalizations

        normalized_html = html.dup
        normalizations.each_value do |normalization_entry|
          normalization_entry.each do |normalization|
            regex = normalization.fetch(:regex)
            replacement = normalization.fetch(:replacement)
            normalized_html.gsub!(%r{#{regex}}, replacement)
          end
        end

        normalized_html
      end
    end
  end
end
