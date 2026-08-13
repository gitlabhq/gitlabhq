# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab-grape-openapi'

require_relative '../../../../tooling/docs/api/tag_content'

RSpec.describe Tasks::Gitlab::Openapi::V3Document, feature_category: :api do
  let(:curated_content) { {} }
  let(:tag_content) { instance_double(::Docs::Api::TagContent, to_h: curated_content) }

  let(:generated_spec) do
    {
      'openapi' => '3.0.0',
      'tags' => [
        { 'name' => 'Access requests', 'description' => 'Generated from the Grape class name.' },
        { 'name' => 'Wikis', 'description' => 'Generated from the Grape class name.' }
      ]
    }
  end

  subject(:document) { described_class.new(tag_content).render }

  before do
    stub_const('Grape::API::Instance', Class.new)
    stub_const('API::Base', Class.new { def self.descendants; end })
    allow(::API::Base).to receive(:descendants).and_return([])

    allow(::Gitlab::GrapeOpenapi::Generator).to receive(:new).and_return(
      instance_double(::Gitlab::GrapeOpenapi::Generator, generate: generated_spec)
    )
  end

  def rendered_tags
    YAML.safe_load(document)['tags']
  end

  def rendered_tag(name)
    rendered_tags.find { |tag| tag['name'] == name }
  end

  it 'prepends the generated-file header' do
    expect(document).to start_with(described_class::INTRODUCTION)
  end

  it 'renders the generated document below the header' do
    expect(rendered_tags).to eq(generated_spec['tags'])
  end

  context 'when curated content matches a tag' do
    let(:curated_content) do
      {
        'access_requests' => {
          'description' => 'Use this API to manage requests for access to groups and projects.',
          'x-displayName' => 'Access requests',
          'externalDocs' => { 'url' => 'https://docs.gitlab.com/api/access_requests/' }
        }
      }
    end

    it 'merges the curated content into the tag whose normalized slug matches' do
      expect(rendered_tag('Access requests')).to eq(
        'name' => 'Access requests',
        'description' => 'Use this API to manage requests for access to groups and projects.',
        'x-displayName' => 'Access requests',
        'externalDocs' => { 'url' => 'https://docs.gitlab.com/api/access_requests/' }
      )
    end

    it 'leaves a tag without curated content untouched' do
      expect(rendered_tag('Wikis')).to eq(
        'name' => 'Wikis',
        'description' => 'Generated from the Grape class name.'
      )
    end
  end

  context 'when curated content omits a field the generated tag provides' do
    let(:curated_content) do
      { 'access_requests' => { 'x-displayName' => 'Access requests' } }
    end

    it 'overrides only the keys the curated content provides' do
      expect(rendered_tag('Access requests')).to eq(
        'name' => 'Access requests',
        'description' => 'Generated from the Grape class name.',
        'x-displayName' => 'Access requests'
      )
    end
  end

  context 'when curated content matches no tag in the document' do
    let(:curated_content) do
      { 'not_a_tag_in_the_document' => { 'description' => 'Orphaned content.' } }
    end

    it 'ignores the curated content' do
      expect(rendered_tags).to eq(generated_spec['tags'])
    end
  end

  context 'when the generated document has no tags' do
    let(:generated_spec) { { 'openapi' => '3.0.0' } }
    let(:curated_content) do
      { 'access_requests' => { 'description' => 'Use this API to manage access requests.' } }
    end

    it 'renders without raising' do
      expect { document }.not_to raise_error
      expect(rendered_tags).to be_nil
    end
  end

  context 'with tag files on disk' do
    let(:tags_dir) { Dir.mktmpdir }
    let(:tag_content) { ::Docs::Api::TagContent.new(tags_dir) }

    after do
      FileUtils.remove_entry(tags_dir)
    end

    def write_tag(slug, content)
      File.write(File.join(tags_dir, "#{slug}.md"), content)
    end

    it 'merges the fields parsed out of the tag file' do
      write_tag('access_requests', <<~MARKDOWN)
        ---
        name: Access requests
        external_docs: https://docs.gitlab.com/api/access_requests/
        ---
        Use this API to manage requests for access to groups and projects.
      MARKDOWN

      expect(rendered_tag('Access requests')).to eq(
        'name' => 'Access requests',
        'description' => 'Use this API to manage requests for access to groups and projects.',
        'x-displayName' => 'Access requests',
        'externalDocs' => { 'url' => 'https://docs.gitlab.com/api/access_requests/' }
      )
    end

    it 'leaves a tag without a tag file untouched' do
      write_tag('access_requests', "Use this API to manage access requests.\n")

      expect(rendered_tag('Wikis')).to eq(
        'name' => 'Wikis',
        'description' => 'Generated from the Grape class name.'
      )
    end
  end
end
