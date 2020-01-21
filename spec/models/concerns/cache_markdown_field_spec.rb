# frozen_string_literal: true

require 'spec_helper'

describe CacheMarkdownField, :clean_gitlab_redis_cache do
  let(:ar_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'issues'
      include CacheMarkdownField
      cache_markdown_field :title, pipeline: :single_line
      cache_markdown_field :description
    end
  end

  let(:other_class) do
    Class.new do
      include CacheMarkdownField

      def initialize(args = {})
        @title, @description, @cached_markdown_version = args[:title], args[:description], args[:cached_markdown_version]
        @title_html, @description_html = args[:title_html], args[:description_html]
        @author, @project = args[:author], args[:project]
      end

      attr_accessor :title, :description, :cached_markdown_version

      cache_markdown_field :title, pipeline: :single_line
      cache_markdown_field :description

      def cache_key
        "cache-key"
      end
    end
  end

  let(:markdown) { '`Foo`' }
  let(:html) { '<p data-sourcepos="1:1-1:5" dir="auto"><code>Foo</code></p>' }

  let(:updated_markdown) { '`Bar`' }
  let(:updated_html) { '<p data-sourcepos="1:1-1:5" dir="auto"><code>Bar</code></p>' }

  let(:cache_version) { Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION << 16 }

  def thing_subclass(klass, extra_attribute)
    Class.new(klass) { attr_accessor(extra_attribute) }
  end

  shared_examples 'a class with cached markdown fields' do
    describe '#cached_html_up_to_date?' do
      let(:thing) { klass.new(title: markdown, title_html: html, cached_markdown_version: cache_version) }

      subject { thing.cached_html_up_to_date?(:title) }

      it 'returns false when the version is absent' do
        thing.cached_markdown_version = nil

        is_expected.to be_falsy
      end

      it 'returns false when the version is too early' do
        thing.cached_markdown_version -= 1

        is_expected.to be_falsy
      end

      it 'returns false when the version is too late' do
        thing.cached_markdown_version += 1

        is_expected.to be_falsy
      end

      it 'returns false when the local version was bumped' do
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:local_markdown_version).and_return(2)
        thing.cached_markdown_version = cache_version

        is_expected.to be_falsy
      end

      it 'returns true when the local version is default' do
        thing.cached_markdown_version = cache_version

        is_expected.to be_truthy
      end

      it 'returns true when the cached version is just right' do
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:local_markdown_version).and_return(2)
        thing.cached_markdown_version = cache_version + 2

        is_expected.to be_truthy
      end
    end

    describe '#latest_cached_markdown_version' do
      let(:thing) { klass.new }

      subject { thing.latest_cached_markdown_version }

      it 'returns default version' do
        thing.cached_markdown_version = nil
        is_expected.to eq(cache_version)
      end
    end

    describe '#refresh_markdown_cache' do
      let(:thing) { klass.new(description: markdown, description_html: html, cached_markdown_version: cache_version) }

      before do
        thing.description = updated_markdown
      end

      it 'fills all html fields' do
        thing.refresh_markdown_cache

        expect(thing.description_html).to eq(updated_html)
      end

      it 'does not save the result' do
        expect(thing).not_to receive(:save_markdown)

        thing.refresh_markdown_cache
      end

      it 'updates the markdown cache version' do
        thing.cached_markdown_version = nil
        thing.refresh_markdown_cache

        expect(thing.cached_markdown_version).to eq(cache_version)
      end
    end

    describe '#refresh_markdown_cache!' do
      let(:thing) { klass.new(description: markdown, description_html: html, cached_markdown_version: cache_version) }

      before do
        thing.description = updated_markdown
      end

      it 'fills all html fields' do
        thing.refresh_markdown_cache!

        expect(thing.description_html).to eq(updated_html)
      end

      it 'saves the changes' do
        expect(thing)
          .to receive(:save_markdown)
          .with("description_html" => updated_html, "title_html" => "", "cached_markdown_version" => cache_version)

        thing.refresh_markdown_cache!
      end
    end

    describe '#banzai_render_context' do
      let(:thing) { klass.new(title: markdown, title_html: html, cached_markdown_version: cache_version) }

      subject(:context) { thing.banzai_render_context(:title) }

      it 'sets project to nil if the object lacks a project' do
        is_expected.to have_key(:project)
        expect(context[:project]).to be_nil
      end

      it 'excludes author if the object lacks an author' do
        is_expected.not_to have_key(:author)
      end

      it 'raises if the context for an unrecognised field is requested' do
        expect { thing.banzai_render_context(:not_found) }.to raise_error(ArgumentError)
      end

      it 'includes the pipeline' do
        title_context = thing.banzai_render_context(:title)

        expect(title_context[:pipeline]).to eq(:single_line)
      end

      it 'returns copies of the context template' do
        template = thing.cached_markdown_fields[:description]
        copy = thing.banzai_render_context(:description)

        expect(copy).not_to be(template)
      end

      context 'with a project' do
        let(:project) { build(:project, group: create(:group)) }
        let(:thing) { thing_subclass(klass, :project).new(title: markdown, title_html: html, project: project) }

        it 'sets the project in the context' do
          is_expected.to have_key(:project)
          expect(context[:project]).to eq(project)
        end
      end

      context 'with an author' do
        let(:thing) { thing_subclass(klass, :author).new(title: markdown, title_html: html, author: :author_value) }

        it 'sets the author in the context' do
          is_expected.to have_key(:author)
          expect(context[:author]).to eq(:author_value)
        end
      end
    end

    describe '#updated_cached_html_for' do
      let(:thing) { klass.new(description: markdown, description_html: html, cached_markdown_version: cache_version) }

      context 'when the markdown cache is outdated' do
        before do
          thing.cached_markdown_version += 1
        end

        it 'calls #refresh_markdown_cache' do
          expect(thing).to receive(:refresh_markdown_cache)

          expect(thing.updated_cached_html_for(:description)).to eq(html)
        end
      end

      context 'when the markdown field does not exist' do
        it 'returns nil' do
          expect(thing.updated_cached_html_for(:something)).to eq(nil)
        end
      end

      context 'when the markdown cache is up to date' do
        it 'does not call #refresh_markdown_cache' do
          expect(thing).not_to receive(:refresh_markdown_cache)

          expect(thing.updated_cached_html_for(:description)).to eq(html)
        end
      end
    end
  end

  context 'for Active record classes' do
    let(:klass) { ar_class }

    it_behaves_like 'a class with cached markdown fields'
  end

  context 'for other classes' do
    let(:klass) { other_class }

    it_behaves_like 'a class with cached markdown fields'
  end
end
