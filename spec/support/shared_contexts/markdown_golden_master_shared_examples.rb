# frozen_string_literal: true

require 'spec_helper'

# See spec/fixtures/markdown/markdown_golden_master_examples.yml for documentation on how this spec works.
RSpec.shared_context 'API::Markdown Golden Master shared context' do |markdown_yml_file_path|
  include ApiHelpers
  include WikiHelpers

  let_it_be(:user) { create(:user, username: 'gfm_user') }

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, :repository, group: group) }

  let_it_be(:label) { create(:label, project: project, title: 'bug') }
  let_it_be(:label2) { create(:label, project: project, title: 'UX bug') }

  let_it_be(:milestone) { create(:milestone, project: project, title: '1.1') }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let_it_be(:project_wiki) { create(:project_wiki, project: project, user: user) }

  let_it_be(:project_wiki_page) { create(:wiki_page, wiki: project_wiki) }

  before(:all) do
    group.add_owner(user)
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  markdown_examples = begin
    yaml = File.read(markdown_yml_file_path)
    YAML.safe_load(yaml, symbolize_names: true, aliases: true)
  end

  it "examples must be unique and alphabetized by name", :unlimited_max_formatted_output_length do
    names = markdown_examples.map { |example| example[:name] }
    expect(names).to eq(names.sort.uniq)
  end

  if focused_markdown_examples_string = ENV['FOCUSED_MARKDOWN_EXAMPLES']
    focused_markdown_examples = focused_markdown_examples_string.split(',').map(&:strip) || []
    markdown_examples.reject! { |markdown_example| focused_markdown_examples.exclude?(markdown_example.fetch(:name)) }
  end

  markdown_examples.each do |markdown_example|
    name = markdown_example.fetch(:name)
    api_context = markdown_example[:api_context]

    if api_context && !name.end_with?("_for_#{api_context}")
      raise "Name must have suffix of '_for_#{api_context}' to the api_context"
    end

    context "for #{name}#{api_context ? " (api_context: #{api_context})" : ''}" do
      let(:pending_reason) do
        pending_value = markdown_example.fetch(:pending, nil)
        get_pending_reason(pending_value)
      end

      let(:example_markdown) { markdown_example.fetch(:markdown) }
      let(:example_html) { markdown_example.fetch(:html) }
      let(:substitutions) { markdown_example.fetch(:substitutions, {}) }

      it "verifies conversion of GFM to HTML", :unlimited_max_formatted_output_length do
        stub_application_setting(plantuml_enabled: true, plantuml_url: 'http://localhost:8080')
        stub_application_setting(kroki_enabled: true, kroki_url: 'http://localhost:8000')

        pending pending_reason if pending_reason

        normalized_example_html = normalize_html(example_html, substitutions)

        api_url = get_url_for_api_context(api_context)

        post api_url, params: { text: example_markdown, gfm: true }
        expect(response).to be_successful
        response_body = Gitlab::Json.parse(response.body)
        # Some requests have the HTML in the `html` key, others in the `body` key.
        response_html = response_body['body'] ? response_body.fetch('body') : response_body.fetch('html')
        normalized_response_html = normalize_html(response_html, substitutions)

        expect(normalized_response_html).to eq(normalized_example_html)
      end

      def get_pending_reason(pending_value)
        return false unless pending_value

        return pending_value if pending_value.is_a?(String)

        pending_value[:backend] || false
      end

      def normalize_html(html, substitutions)
        normalized_html = html.dup
        # Note: having the top level `substitutions` data structure be a hash of arrays
        # allows us to compose multiple substitutions via YAML anchors (YAML anchors
        # pointing to arrays can't be combined)
        substitutions.each_value do |substitution_entry|
          substitution_entry.each do |substitution|
            regex = substitution.fetch(:regex)
            replacement = substitution.fetch(:replacement)
            normalized_html.gsub!(%r{#{regex}}, replacement)
          end
        end

        normalized_html
      end
    end
  end

  def supported_api_contexts
    %w(project group project_wiki)
  end

  def get_url_for_api_context(api_context)
    case api_context
    when 'project'
      "/#{project.full_path}/preview_markdown"
    when 'group'
      "/groups/#{group.full_path}/preview_markdown"
    when 'project_wiki'
      "/#{project.full_path}/-/wikis/#{project_wiki_page.slug}/preview_markdown"
    when nil
      api "/markdown"
    else
      raise "Error: 'context' extension was '#{api_context}'. It must be one of: #{supported_api_contexts.join(',')}"
    end
  end
end
