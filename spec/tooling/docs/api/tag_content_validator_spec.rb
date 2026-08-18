# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../tooling/docs/api/tag_content_validator'

RSpec.describe Docs::Api::TagContentValidator, feature_category: :api do
  let(:tags_dir) { Dir.mktmpdir }
  let(:declared_slugs) { %w[issues] }
  let(:tag_content) { ::Docs::Api::TagContent.new(tags_dir) }

  subject(:result) { described_class.new(tag_content).validate(declared_slugs) }

  before do
    FileUtils.cp(File.join(::Docs::Api::TagContent::TAGS_DIR, described_class::SCHEMA_FILE), tags_dir)
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

  describe '#json_schema_file' do
    it 'resolves the schema against the tag directory' do
      expect(described_class.new(tag_content).json_schema_file)
        .to eq(File.join(tags_dir, 'type_schema.json'))
    end
  end

  context 'when all tag content is valid' do
    it 'reports no violations and counts the files checked' do
      valid_tag('issues', 'Issues')

      expect(result).to be_valid
      expect(result.checked).to eq(1)
    end

    it 'is valid when the directory is empty' do
      expect(result).to be_valid
      expect(result.checked).to eq(0)
    end
  end

  describe 'front matter that does not match the schema' do
    it 'reports a file missing the required name key' do
      write_tag('issues', <<~MARKDOWN)
        ---
        external_docs: https://docs.gitlab.com/api/issues/
        ---
        Use this API to manage issues.
      MARKDOWN

      expect(result).not_to be_valid
      expect(result.schema.keys).to contain_exactly(File.join(tags_dir, 'issues.md'))
      expect(result.schema.values.flatten.map { |error| error['type'] }).to include('required')
    end

    it 'reports a file with an unknown key' do
      write_tag('issues', <<~MARKDOWN)
        ---
        name: Issues
        unknown_key: nope
        ---
        Use this API to manage issues.
      MARKDOWN

      expect(result.schema.keys).to contain_exactly(File.join(tags_dir, 'issues.md'))
    end

    it 'reports a file that sets x-displayName instead of name' do
      write_tag('issues', <<~MARKDOWN)
        ---
        name: Issues
        x-displayName: Issue tracker
        ---
        Use this API to manage issues.
      MARKDOWN

      expect(result.schema.keys).to contain_exactly(File.join(tags_dir, 'issues.md'))
    end

    it 'treats front matter that is not valid YAML as empty' do
      write_tag('issues', <<~MARKDOWN)
        ---
        name: Issues: broken
        ---
        Use this API to manage issues.
      MARKDOWN

      expect(result.schema.keys).to contain_exactly(File.join(tags_dir, 'issues.md'))
    end
  end

  describe 'files with no matching tag in the API code' do
    it 'reports the file as an orphan' do
      valid_tag('issues', 'Issues')
      valid_tag('not_a_real_tag', 'Not a real tag')

      expect(result.orphan).to contain_exactly(File.join(tags_dir, 'not_a_real_tag.md'))
    end

    it 'does not report a file whose slug matches a declared tag' do
      valid_tag('issues', 'Issues')

      expect(result.orphan).to be_empty
    end

    context 'when two files normalize to the same tag name' do
      let(:declared_slugs) { %w[access_requests] }

      it 'reports the variant rather than letting it replace the declared tag' do
        valid_tag('access_requests', 'Access requests')
        valid_tag('access requests', 'Access requests')

        expect(result.orphan).to contain_exactly(File.join(tags_dir, 'access requests.md'))
      end
    end
  end

  describe 'files with an empty description' do
    it 'reports the file' do
      write_tag('issues', <<~MARKDOWN)
        ---
        name: Issues
        ---
      MARKDOWN

      expect(result.description).to contain_exactly(File.join(tags_dir, 'issues.md'))
    end
  end

  context 'when several violation types are present' do
    it 'reports all of them in one result' do
      write_tag('issues', "---\nname: Issues\n---\n")
      valid_tag('not_a_real_tag', 'Not a real tag')

      expect(result.orphan).to contain_exactly(File.join(tags_dir, 'not_a_real_tag.md'))
      expect(result.description).to contain_exactly(File.join(tags_dir, 'issues.md'))
    end
  end
end
