# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../tooling/docs/api/tag_content_validator'

RSpec.describe Tasks::Gitlab::Openapi::ValidateTagDocsTask, feature_category: :api do
  let(:tags_dir) { Dir.mktmpdir }
  let(:declared_tags) { %w[issues] }

  # Stand-ins for classes that are not loaded under fast_spec_helper, so the doubles stay verified.
  let(:route_class) { Class.new { def settings; end } }
  let(:configuration_class) { Class.new { def excluded_api_classes; end } }

  let(:api_class_stub) do
    Class.new do
      def name; end

      def routes; end
    end
  end

  let(:route) { instance_double(route_class, settings: { description: { tags: declared_tags } }) }

  subject(:task) { described_class.new }

  before do
    FileUtils.cp(
      File.join(::Docs::Api::TagContent::TAGS_DIR, ::Docs::Api::TagContentValidator::SCHEMA_FILE),
      tags_dir
    )

    allow(::Docs::Api::TagContentValidator).to receive(:new).and_return(
      ::Docs::Api::TagContentValidator.new(::Docs::Api::TagContent.new(tags_dir))
    )

    api_class = instance_double(api_class_stub, name: 'API::Issues', routes: [route])

    # Stub Grape before API::Base so that stubbing does not autoload the real Grape-dependent class.
    # The stand-ins declare the methods stubbed below so the doubles stay verified.
    stub_const('Grape::API::Instance', Class.new)
    stub_const('API::Base', Class.new { def self.descendants; end })
    stub_const('API::API', Class.new)
    allow(::API::Base).to receive(:descendants).and_return([api_class])

    stub_const('Gitlab::GrapeOpenapi', Module.new { def self.configuration; end })
    allow(::Gitlab::GrapeOpenapi).to receive(:configuration).and_return(
      instance_double(configuration_class, excluded_api_classes: [])
    )
  end

  after do
    FileUtils.remove_entry(tags_dir)
  end

  def write_tag(slug, content)
    File.write(File.join(tags_dir, "#{slug}.md"), content)
  end

  def valid_tag(slug, name)
    write_tag(slug, <<~MARKDOWN)
      ---
      name: #{name}
      ---
      Use this API to manage #{name.downcase}.
    MARKDOWN
  end

  context 'when all tag content is valid' do
    it 'reports the number of files checked' do
      valid_tag('issues', 'Issues')

      expect { task.run }.to output(/API tag content is valid \(1 file\)/).to_stdout
    end

    it 'reports zero files when the directory is empty' do
      expect { task.run }.to output(/API tag content is valid \(0 files\)/).to_stdout
    end
  end

  context 'when front matter does not match the schema' do
    it 'prints the offending file, the schema location, and the schema errors' do
      write_tag('issues', <<~MARKDOWN)
        ---
        external_docs: https://docs.gitlab.com/api/issues/
        ---
        Use this API to manage issues.
      MARKDOWN

      expect { task.run }.to raise_error(SystemExit).and output(
        /invalid front matter\..*Allowed keys are defined in.*type_schema\.json.*issues\.md.*required keys: name/m
      ).to_stdout
    end
  end

  context 'when a tag file has no matching tag in the API code' do
    it 'prints the file as an orphan' do
      valid_tag('issues', 'Issues')
      valid_tag('not_a_real_tag', 'Not a real tag')

      expect { task.run }.to raise_error(SystemExit).and output(
        /The following API tag content files do not match a tag declared by any API endpoint\..*not_a_real_tag\.md/m
      ).to_stdout
    end
  end

  context 'when a tag file has an empty description' do
    it 'prints the file' do
      write_tag('issues', <<~MARKDOWN)
        ---
        name: Issues
        ---
      MARKDOWN

      expect { task.run }.to raise_error(SystemExit)
        .and output(/The following API tag content files have an empty description\..*issues\.md/m).to_stdout
    end
  end

  context 'when several violation types are present' do
    it 'prints all of them in one run' do
      write_tag('issues', "---\nname: Issues\n---\n")
      valid_tag('not_a_real_tag', 'Not a real tag')

      expect { task.run }.to raise_error(SystemExit).and output(
        /do not match a tag declared by any API endpoint\..*have an empty description\./m
      ).to_stdout
    end
  end

  context 'when a route declares tags as a bare string' do
    let(:declared_tags) { 'issues' }

    it 'treats the value as a single tag' do
      valid_tag('issues', 'Issues')

      expect { task.run }.to output(/is valid/).to_stdout
    end
  end
end
