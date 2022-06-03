# frozen_string_literal: true

require 'spec_helper'

# See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
# for documentation on this spec.
RSpec.shared_context 'API::Markdown Snapshot shared context' do |glfm_example_snapshots_dir|
  include ApiHelpers

  markdown_examples, html_examples = %w[markdown.yml html.yml].map do |file_name|
    yaml = File.read("#{glfm_example_snapshots_dir}/#{file_name}")
    YAML.safe_load(yaml, symbolize_names: true, aliases: true)
  end

  if focused_markdown_examples_string = ENV['FOCUSED_MARKDOWN_EXAMPLES']
    focused_markdown_examples = focused_markdown_examples_string.split(',').map(&:strip).map(&:to_sym)
    markdown_examples.select! { |example_name| focused_markdown_examples.include?(example_name) }
  end

  markdown_examples.each do |name, markdown|
    context "for #{name}" do
      let(:html) { html_examples.fetch(name).fetch(:static) }

      it "verifies conversion of GLFM to HTML", :unlimited_max_formatted_output_length do
        api_url = api "/markdown"

        post api_url, params: { text: markdown, gfm: true }
        expect(response).to be_successful
        response_body = Gitlab::Json.parse(response.body)
        # Some requests have the HTML in the `html` key, others in the `body` key.
        response_html = response_body['body'] ? response_body.fetch('body') : response_body.fetch('html')

        expect(response_html).to eq(html)
      end
    end
  end
end
