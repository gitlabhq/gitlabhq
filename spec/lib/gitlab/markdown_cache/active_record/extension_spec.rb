# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::MarkdownCache::ActiveRecord::Extension, feature_category: :wiki do
  let_it_be(:project) { create(:project) }

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'issues'
      include CacheMarkdownField
      cache_markdown_field :title, whitelisted: true
      cache_markdown_field :description, pipeline: :single_line

      attribute :author
      attribute :project

      before_validation -> { self.work_item_type_id = ::WorkItems::Type.default_issue_type.id }
    end
  end

  let(:cache_version) { Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION_SHIFTED }
  let(:thing) do
    klass.create!(
      project_id: project.id, namespace_id: project.project_namespace_id,
      title: markdown, title_html: html, cached_markdown_version: cache_version
    )
  end

  let(:markdown) { '`Foo`' }
  let(:html) { '<p dir="auto"><code>Foo</code></p>' }

  let(:updated_markdown) { '`Bar`' }
  let(:updated_html) { '<p dir="auto"><code>Bar</code></p>' }

  before do
    stub_commonmark_sourcepos_disabled
  end

  context 'an unchanged markdown field' do
    let(:thing) { klass.new(project_id: project.id, namespace_id: project.project_namespace_id, title: markdown) }

    before do
      thing.title = thing.title
      thing.save!
    end

    it { expect(thing.title).to eq(markdown) }
    it { expect(thing.title_html).to eq(html) }
    it { expect(thing.title_html_changed?).not_to be_truthy }
    it { expect(thing.cached_markdown_version).to eq(cache_version) }
  end

  context 'a changed markdown field' do
    let(:thing) do
      klass.create!(
        project_id: project.id, namespace_id: project.project_namespace_id,
        title: markdown, title_html: html, cached_markdown_version: cache_version
      )
    end

    before do
      thing.title = updated_markdown
      thing.save!
    end

    it { expect(thing.title_html).to eq(updated_html) }
    it { expect(thing.cached_markdown_version).to eq(cache_version) }
  end

  context 'when a markdown field is set repeatedly to an empty string' do
    it do
      expect(thing).to receive(:refresh_markdown_cache).once
      thing.title = ''
      thing.save!
      thing.title = ''
      thing.save!
    end
  end

  context 'when a markdown field is set repeatedly to a string which renders as empty html' do
    it do
      expect(thing).to receive(:refresh_markdown_cache).once
      thing.title = '[//]: # (This is also a comment.)'
      thing.save!
      thing.title = '[//]: # (This is also a comment.)'
      thing.save!
    end
  end

  context 'a non-markdown field changed' do
    let(:thing) do
      klass.new(
        project_id: project.id, namespace_id: project.project_namespace_id, title: markdown,
        title_html: html, cached_markdown_version: cache_version
      )
    end

    before do
      thing.state_id = 2
      thing.save!
    end

    it { expect(thing.state_id).to eq(2) }
    it { expect(thing.title).to eq(markdown) }
    it { expect(thing.title_html).to eq(html) }
    it { expect(thing.cached_markdown_version).to eq(cache_version) }
  end

  context 'version is out of date' do
    let(:thing) do
      klass.new(
        project_id: project.id, namespace_id: project.project_namespace_id,
        title: updated_markdown, title_html: html, cached_markdown_version: nil
      )
    end

    before do
      thing.save!
    end

    it { expect(thing.title_html).to eq(updated_html) }
    it { expect(thing.cached_markdown_version).to eq(cache_version) }
  end

  context 'when an invalidating field is changed' do
    it 'invalidates the cache when project changes' do
      thing.project = :new_project
      allow(Banzai::Renderer).to receive(:cacheless_render_field).and_return(updated_html)

      thing.save!

      expect(thing.title_html).to eq(updated_html)
      expect(thing.description_html).to eq(updated_html)
      expect(thing.cached_markdown_version).to eq(cache_version)
    end

    it 'invalidates the cache when author changes' do
      thing.author = :new_author
      allow(Banzai::Renderer).to receive(:cacheless_render_field).and_return(updated_html)

      thing.save!

      expect(thing.title_html).to eq(updated_html)
      expect(thing.description_html).to eq(updated_html)
      expect(thing.cached_markdown_version).to eq(cache_version)
    end
  end

  describe '.attributes' do
    it 'excludes cache attributes that are denylisted by default' do
      expect(thing.attributes.keys.sort).not_to include(%w[description_html])
    end
  end

  describe '#cached_html_up_to_date?' do
    let(:thing) do
      klass.create!(
        project_id: project.id, namespace_id: project.project_namespace_id,
        title: updated_markdown, title_html: html, cached_markdown_version: nil
      )
    end

    subject { thing.cached_html_up_to_date?(:title) }

    it 'returns false if markdown has been changed but html has not' do
      thing.title = "changed!"

      is_expected.to be_falsy
    end

    it 'returns true if markdown has not been changed but html has' do
      thing.title_html = updated_html

      is_expected.to be_truthy
    end

    it 'returns true if markdown and html have both been changed' do
      thing.title = updated_markdown
      thing.title_html = updated_html

      is_expected.to be_truthy
    end

    it 'returns false if the markdown field is set but the html is not' do
      thing.title_html = nil

      is_expected.to be_falsy
    end
  end

  describe '#refresh_markdown_cache!' do
    before do
      thing.title = updated_markdown
    end

    it 'skips saving if not persisted' do
      expect(thing).to receive(:persisted?).and_return(false)
      expect(thing).not_to receive(:update_columns)

      thing.refresh_markdown_cache!
    end

    it 'saves the changes' do
      expect(thing).to receive(:persisted?).and_return(true)

      expect(thing).to receive(:update_columns)
                         .with({ "title_html" => updated_html,
                                 "description_html" => "",
                                 "cached_markdown_version" => cache_version })

      thing.refresh_markdown_cache!
    end
  end

  context 'with note' do
    let(:klass) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'notes'
        include CacheMarkdownField
        include Importable
        include Mentionable

        attr_mentionable :note, pipeline: :note
        cache_markdown_field :note, pipeline: :note
      end
    end

    let(:thing) { klass.new(note: markdown, project_id: project.id) }

    before do
      thing.note = "hello world"
      thing.noteable_type = "Issue"
    end

    it 'calls store_mentions!' do
      expect(thing).to receive(:store_mentions!).and_call_original

      thing.save!
    end

    context 'during import' do
      before do
        thing.importing = true
      end

      it 'does not call store_mentions!' do
        expect(thing).not_to receive(:store_mentions!)

        thing.save!
      end
    end
  end

  context 'when persisted cache is newer than current version' do
    before do
      thing.update_column(:cached_markdown_version, thing.cached_markdown_version + 1)
    end

    it 'does not save the generated HTML' do
      expect(thing).not_to receive(:update_columns)

      thing.refresh_markdown_cache!
    end
  end

  context 'when persisted cache is nil' do
    before do
      thing.update_column(:cached_markdown_version, nil)
    end

    it 'does not save the generated HTML' do
      expect(thing).to receive(:update_columns)

      thing.refresh_markdown_cache!
    end
  end
end
