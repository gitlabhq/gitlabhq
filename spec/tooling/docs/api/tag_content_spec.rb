# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../tooling/docs/api/tag_content'

RSpec.describe Docs::Api::TagContent, feature_category: :api do
  let(:tags_dir) { Dir.mktmpdir }

  subject(:tag_content) { described_class.new(tags_dir) }

  after do
    FileUtils.remove_entry(tags_dir)
  end

  def write_tag(slug, content)
    File.write(File.join(tags_dir, "#{slug}.md"), content)
  end

  describe '#[]' do
    it 'maps front matter and body to OpenAPI tag fields' do
      write_tag('access_requests', <<~MARKDOWN)
        ---
        name: Access requests
        external_docs: https://docs.gitlab.com/api/access_requests/
        ---
        Manage requests for access to groups and projects.
      MARKDOWN

      expect(tag_content['access_requests']).to eq(
        'description' => 'Manage requests for access to groups and projects.',
        'x-displayName' => 'Access requests',
        'externalDocs' => { 'url' => 'https://docs.gitlab.com/api/access_requests/' }
      )
    end

    it 'passes through x- prefixed front matter keys' do
      write_tag('branches', <<~MARKDOWN)
        ---
        name: Branches
        x-gitlab-status: beta
        ---
        Read and write repository branches.
      MARKDOWN

      expect(tag_content['branches']).to include(
        'x-displayName' => 'Branches',
        'x-gitlab-status' => 'beta'
      )
    end

    it 'omits fields that are absent from the front matter' do
      write_tag('commits', <<~MARKDOWN)
        ---
        name: Commits
        ---
        Read repository commits.
      MARKDOWN

      expect(tag_content['commits']).to eq(
        'description' => 'Read repository commits.',
        'x-displayName' => 'Commits'
      )
    end

    it 'treats a file without front matter as description only' do
      write_tag('deployments', "Manage deployments.\n")

      expect(tag_content['deployments']).to eq('description' => 'Manage deployments.')
    end

    it 'omits the description when the body is blank' do
      write_tag('events', <<~MARKDOWN)
        ---
        name: Events
        ---
      MARKDOWN

      expect(tag_content['events']).to eq('x-displayName' => 'Events')
    end

    it 'preserves multi-paragraph bodies' do
      write_tag('groups', <<~MARKDOWN)
        ---
        name: Groups
        ---
        First paragraph.

        Second paragraph.
      MARKDOWN

      expect(tag_content['groups']['description']).to eq("First paragraph.\n\nSecond paragraph.")
    end

    it 'returns nil for a slug without a file' do
      expect(tag_content['does_not_exist']).to be_nil
    end

    it 'treats front matter that is not valid YAML as empty and keeps the body' do
      write_tag('packages_conan', <<~MARKDOWN)
        ---
        name: Packages: Conan
        ---
        Interact with the Conan package manager.
      MARKDOWN

      expect(tag_content['packages_conan']).to eq(
        'description' => 'Interact with the Conan package manager.'
      )
    end

    it 'treats front matter holding a class that is not permitted as empty and keeps the body' do
      write_tag('releases', <<~MARKDOWN)
        ---
        name: Releases
        x-gitlab-added: 2026-01-01
        ---
        Manage releases.
      MARKDOWN

      expect(tag_content['releases']).to eq('description' => 'Manage releases.')
    end
  end

  describe '#to_h' do
    it 'is keyed by slug and memoized' do
      write_tag('issues', "Manage issues.\n")

      expect(tag_content.to_h.keys).to eq(%w[issues])

      write_tag('labels', "Manage labels.\n")

      expect(tag_content.to_h.keys).to eq(%w[issues])
    end

    it 'is empty when the directory holds no markdown files' do
      expect(tag_content.to_h).to eq({})
    end
  end

  describe '#tag_files' do
    it 'returns the markdown files in the directory and ignores everything else' do
      write_tag('issues', "Manage issues.\n")
      File.write(File.join(tags_dir, 'type_schema.json'), '{}')

      expect(tag_content.tag_files).to contain_exactly(File.join(tags_dir, 'issues.md'))
    end

    it 'is empty when the directory holds no markdown files' do
      expect(tag_content.tag_files).to be_empty
    end
  end

  describe '#slugs' do
    it 'returns the slug of every tag file' do
      write_tag('issues', "Manage issues.\n")
      write_tag('labels', "Manage labels.\n")

      expect(tag_content.slugs).to contain_exactly('issues', 'labels')
    end
  end

  describe '#front_matter_for' do
    it 'returns the parsed front matter hash' do
      write_tag('members', <<~MARKDOWN)
        ---
        name: Members
        external_docs: https://docs.gitlab.com/api/members/
        ---
        Manage members.
      MARKDOWN

      expect(tag_content.front_matter_for(File.join(tags_dir, 'members.md'))).to eq(
        'name' => 'Members',
        'external_docs' => 'https://docs.gitlab.com/api/members/'
      )
    end

    it 'returns an empty hash when the file has no front matter' do
      write_tag('notes', "Manage notes.\n")

      expect(tag_content.front_matter_for(File.join(tags_dir, 'notes.md'))).to eq({})
    end

    it 'returns an empty hash when the front matter is not valid YAML' do
      write_tag('pipelines', <<~MARKDOWN)
        ---
        name: Pipelines: broken
        ---
        Manage pipelines.
      MARKDOWN

      expect(tag_content.front_matter_for(File.join(tags_dir, 'pipelines.md'))).to eq({})
    end
  end
end
