# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CacheMarkdownField, :clean_gitlab_redis_cache do
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
        @title = args[:title]
        @description = args[:description]
        @cached_markdown_version = args[:cached_markdown_version]
        @title_html = args[:title_html]
        @description_html = args[:description_html]
        @author = args[:author]
        @project = args[:project]
        @parent_user = args[:parent_user]
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

  def thing_subclass(klass, *extra_attributes)
    Class.new(klass) { attr_accessor(*extra_attributes) }
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
        stub_application_setting(local_markdown_version: 2)
        thing.cached_markdown_version = cache_version

        is_expected.to be_falsy
      end

      it 'returns true when the local version is default' do
        thing.cached_markdown_version = cache_version

        is_expected.to be_truthy
      end

      it 'returns true when the cached version is just right' do
        stub_application_setting(local_markdown_version: 2)
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
        let(:user) { build(:user) }
        let(:thing) { thing_subclass(klass, :author).new(title: markdown, title_html: html, author: user) }

        it 'sets the author in the context' do
          is_expected.to have_key(:author)
          expect(context[:author]).to eq(user)
        end
      end

      context 'with a parent_user' do
        let(:user) { build(:user) }
        let(:thing) { thing_subclass(klass, :author, :parent_user).new(title: markdown, title_html: html, parent_user: user, author: user) }

        it 'sets the user in the context' do
          is_expected.to have_key(:user)
          expect(context[:user]).to eq(user)
        end

        context 'when the personal_snippet_reference_filters flag is disabled' do
          before do
            stub_feature_flags(personal_snippet_reference_filters: false)
          end

          it 'does not set the user in the context' do
            is_expected.not_to have_key(:user)
            expect(context[:user]).to be_nil
          end
        end
      end
    end

    describe '#updated_cached_html_for' do
      let(:thing) { klass.new(description: markdown, description_html: html, cached_markdown_version: cache_version) }

      context 'when the markdown cache is outdated' do
        before do
          thing.cached_markdown_version += 1
        end

        it 'calls #refresh_markdown_cache!' do
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
        before do
          thing.try(:save)
        end

        it 'does not call #refresh_markdown_cache!' do
          expect(thing).not_to receive(:refresh_markdown_cache!)

          expect(thing.updated_cached_html_for(:description)).to eq(html)
        end
      end
    end

    describe '#rendered_field_content' do
      let(:thing) { klass.new(description: markdown, description_html: nil, cached_markdown_version: cache_version) }

      context 'when a field can be cached' do
        it 'returns the html' do
          thing.description = updated_markdown

          expect(thing.rendered_field_content(:description)).to eq updated_html
        end
      end

      context 'when a field cannot be cached' do
        it 'returns nil' do
          allow(thing).to receive(:can_cache_field?).with(:description).and_return false

          expect(thing.rendered_field_content(:description)).to eq nil
        end
      end
    end
  end

  shared_examples 'a class with mentionable markdown fields' do
    let(:mentionable) { klass.new(description: markdown, description_html: html, title: markdown, title_html: html, cached_markdown_version: cache_version) }

    context 'when klass is a Mentionable', :aggregate_failures do
      before do
        klass.send(:include, Mentionable)
        klass.send(:attr_mentionable, :description)
      end

      describe '#mentionable_attributes_changed?' do
        message = Struct.new(:text)

        let(:changes) do
          msg = message.new('test')

          changes = {}
          changes[msg] = ['', 'some message']
          changes[:random_sym_key] = ['', 'some message']
          changes["description"] = ['', 'some message']
          changes
        end

        it 'returns true with key string' do
          changes["description_html"] = ['', 'some message']

          allow(mentionable).to receive(:saved_changes).and_return(changes)

          expect(mentionable.send(:mentionable_attributes_changed?)).to be true
        end

        it 'returns false with key symbol' do
          changes[:description_html] = ['', 'some message']
          allow(mentionable).to receive(:saved_changes).and_return(changes)

          expect(mentionable.send(:mentionable_attributes_changed?)).to be false
        end

        it 'returns false when no attr_mentionable keys' do
          allow(mentionable).to receive(:saved_changes).and_return(changes)

          expect(mentionable.send(:mentionable_attributes_changed?)).to be false
        end
      end

      describe '#save' do
        context 'when cache is outdated' do
          before do
            thing.cached_markdown_version += 1
          end

          context 'when the markdown field also a mentionable attribute' do
            let(:thing) { klass.new(description: markdown, description_html: html, cached_markdown_version: cache_version) }

            it 'calls #store_mentions!' do
              expect(thing).to receive(:mentionable_attributes_changed?).and_return(true)
              expect(thing).to receive(:store_mentions!)

              thing.try(:save)

              expect(thing.description_html).to eq(html)
            end
          end

          context 'when the markdown field is not mentionable attribute' do
            let(:thing) { klass.new(title: markdown, title_html: html, cached_markdown_version: cache_version) }

            it 'does not call #store_mentions!' do
              expect(thing).not_to receive(:store_mentions!)
              expect(thing).to receive(:refresh_markdown_cache)

              thing.try(:save)

              expect(thing.title_html).to eq(html)
            end
          end
        end

        context 'when the markdown field does not exist' do
          let(:thing) { klass.new(cached_markdown_version: cache_version) }

          it 'does not call #store_mentions!' do
            expect(thing).not_to receive(:store_mentions!)

            thing.try(:save)
          end
        end
      end
    end
  end

  context 'for Active record classes' do
    let(:klass) { ar_class }

    it_behaves_like 'a class with cached markdown fields'
    it_behaves_like 'a class with mentionable markdown fields'

    describe '#attribute_invalidated?' do
      let(:thing) { klass.create!(description: markdown, description_html: html, cached_markdown_version: cache_version) }

      it 'returns true when cached_markdown_version is different' do
        thing.cached_markdown_version += 1

        expect(thing.attribute_invalidated?(:description_html)).to eq(true)
      end

      it 'returns true when markdown is changed' do
        thing.description = updated_markdown

        expect(thing.attribute_invalidated?(:description_html)).to eq(true)
      end

      it 'returns true when both markdown and HTML are changed' do
        thing.description = updated_markdown
        thing.description_html = updated_html

        expect(thing.attribute_invalidated?(:description_html)).to eq(true)
      end

      it 'returns false when there are no changes' do
        expect(thing.attribute_invalidated?(:description_html)).to eq(false)
      end
    end

    context 'when cache version is updated' do
      let(:old_version) { cache_version - 1 }
      let(:old_html) { '<p data-sourcepos="1:1-1:5" dir="auto" class="some-old-class"><code>Foo</code></p>' }

      let(:thing) do
        # This forces the record to have outdated HTML. We can't use `create` because the `before_create` hook
        # would re-render the HTML to the latest version
        klass.create!.tap do |thing|
          thing.update_columns(description: markdown, description_html: old_html, cached_markdown_version: old_version)
        end
      end

      it 'correctly updates cached HTML even if refresh_markdown_cache is called before updating the attribute' do
        thing.refresh_markdown_cache

        thing.update!(description: updated_markdown)

        expect(thing.description_html).to eq(updated_html)
      end
    end
  end

  context 'for other classes' do
    let(:klass) { other_class }

    it_behaves_like 'a class with cached markdown fields'
  end
end
