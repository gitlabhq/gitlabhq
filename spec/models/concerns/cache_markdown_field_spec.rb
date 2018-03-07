require 'spec_helper'

describe CacheMarkdownField do
  # The minimum necessary ActiveModel to test this concern
  class ThingWithMarkdownFields
    include ActiveModel::Model
    include ActiveModel::Dirty

    include ActiveModel::Serialization

    class_attribute :attribute_names
    self.attribute_names = []

    def attributes
      attribute_names.each_with_object({}) do |name, hsh|
        hsh[name.to_s] = send(name)
      end
    end

    extend ActiveModel::Callbacks
    define_model_callbacks :create, :update

    include CacheMarkdownField
    cache_markdown_field :foo
    cache_markdown_field :baz, pipeline: :single_line

    def self.add_attr(name)
      self.attribute_names += [name]
      define_attribute_methods(name)
      attr_reader(name)
      define_method("#{name}=") do |value|
        write_attribute(name, value)
      end
    end

    add_attr :cached_markdown_version

    [:foo, :foo_html, :bar, :baz, :baz_html].each do |name|
      add_attr(name)
    end

    def initialize(*)
      super

      # Pretend new is load
      clear_changes_information
    end

    def read_attribute(name)
      instance_variable_get("@#{name}")
    end

    def write_attribute(name, value)
      send("#{name}_will_change!") unless value == read_attribute(name)
      instance_variable_set("@#{name}", value)
    end

    def save
      run_callbacks :update do
        changes_applied
      end
    end
  end

  def thing_subclass(new_attr)
    Class.new(ThingWithMarkdownFields) { add_attr(new_attr) }
  end

  let(:markdown) { '`Foo`' }
  let(:html) { '<p dir="auto"><code>Foo</code></p>' }

  let(:updated_markdown) { '`Bar`' }
  let(:updated_html) { '<p dir="auto"><code>Bar</code></p>' }

  let(:thing) { ThingWithMarkdownFields.new(foo: markdown, foo_html: html, cached_markdown_version: CacheMarkdownField::CACHE_VERSION) }

  describe '.attributes' do
    it 'excludes cache attributes' do
      expect(thing.attributes.keys.sort).to eq(%w[bar baz foo])
    end
  end

  context 'an unchanged markdown field' do
    before do
      thing.foo = thing.foo
      thing.save
    end

    it { expect(thing.foo).to eq(markdown) }
    it { expect(thing.foo_html).to eq(html) }
    it { expect(thing.foo_html_changed?).not_to be_truthy }
    it { expect(thing.cached_markdown_version).to eq(CacheMarkdownField::CACHE_VERSION) }
  end

  context 'a changed markdown field' do
    before do
      thing.foo = updated_markdown
      thing.save
    end

    it { expect(thing.foo_html).to eq(updated_html) }
    it { expect(thing.cached_markdown_version).to eq(CacheMarkdownField::CACHE_VERSION) }
  end

  context 'when a markdown field is set repeatedly to an empty string' do
    it do
      expect(thing).to receive(:refresh_markdown_cache).once
      thing.foo = ''
      thing.save
      thing.foo = ''
      thing.save
    end
  end

  context 'when a markdown field is set repeatedly to a string which renders as empty html' do
    it do
      expect(thing).to receive(:refresh_markdown_cache).once
      thing.foo = '[//]: # (This is also a comment.)'
      thing.save
      thing.foo = '[//]: # (This is also a comment.)'
      thing.save
    end
  end

  context 'a non-markdown field changed' do
    before do
      thing.bar = 'OK'
      thing.save
    end

    it { expect(thing.bar).to eq('OK') }
    it { expect(thing.foo).to eq(markdown) }
    it { expect(thing.foo_html).to eq(html) }
    it { expect(thing.cached_markdown_version).to eq(CacheMarkdownField::CACHE_VERSION) }
  end

  context 'version is out of date' do
    let(:thing) { ThingWithMarkdownFields.new(foo: updated_markdown, foo_html: html, cached_markdown_version: nil) }

    before do
      thing.save
    end

    it { expect(thing.foo_html).to eq(updated_html) }
    it { expect(thing.cached_markdown_version).to eq(CacheMarkdownField::CACHE_VERSION) }
  end

  describe '#cached_html_up_to_date?' do
    subject { thing.cached_html_up_to_date?(:foo) }

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

    it 'returns true when the version is just right' do
      thing.cached_markdown_version = CacheMarkdownField::CACHE_VERSION

      is_expected.to be_truthy
    end

    it 'returns false if markdown has been changed but html has not' do
      thing.foo = updated_html

      is_expected.to be_falsy
    end

    it 'returns true if markdown has not been changed but html has' do
      thing.foo_html = updated_html

      is_expected.to be_truthy
    end

    it 'returns true if markdown and html have both been changed' do
      thing.foo = updated_markdown
      thing.foo_html = updated_html

      is_expected.to be_truthy
    end

    it 'returns false if the markdown field is set but the html is not' do
      thing.foo_html = nil

      is_expected.to be_falsy
    end
  end

  describe '#refresh_markdown_cache' do
    before do
      thing.foo = updated_markdown
    end

    it 'fills all html fields' do
      thing.refresh_markdown_cache

      expect(thing.foo_html).to eq(updated_html)
      expect(thing.foo_html_changed?).to be_truthy
      expect(thing.baz_html_changed?).to be_truthy
    end

    it 'does not save the result' do
      expect(thing).not_to receive(:update_columns)

      thing.refresh_markdown_cache
    end

    it 'updates the markdown cache version' do
      thing.cached_markdown_version = nil
      thing.refresh_markdown_cache

      expect(thing.cached_markdown_version).to eq(CacheMarkdownField::CACHE_VERSION)
    end
  end

  describe '#refresh_markdown_cache!' do
    before do
      thing.foo = updated_markdown
    end

    it 'fills all html fields' do
      thing.refresh_markdown_cache!

      expect(thing.foo_html).to eq(updated_html)
      expect(thing.foo_html_changed?).to be_truthy
      expect(thing.baz_html_changed?).to be_truthy
    end

    it 'skips saving if not persisted' do
      expect(thing).to receive(:persisted?).and_return(false)
      expect(thing).not_to receive(:update_columns)

      thing.refresh_markdown_cache!
    end

    it 'saves the changes using #update_columns' do
      expect(thing).to receive(:persisted?).and_return(true)
      expect(thing).to receive(:update_columns)
        .with("foo_html" => updated_html, "baz_html" => "", "cached_markdown_version" => CacheMarkdownField::CACHE_VERSION)

      thing.refresh_markdown_cache!
    end
  end

  describe '#banzai_render_context' do
    subject(:context) { thing.banzai_render_context(:foo) }

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
      baz = thing.banzai_render_context(:baz)

      expect(baz[:pipeline]).to eq(:single_line)
    end

    it 'returns copies of the context template' do
      template = thing.cached_markdown_fields[:baz]
      copy = thing.banzai_render_context(:baz)

      expect(copy).not_to be(template)
    end

    context 'with a project' do
      let(:thing) { thing_subclass(:project).new(foo: markdown, foo_html: html, project: :project_value) }

      it 'sets the project in the context' do
        is_expected.to have_key(:project)
        expect(context[:project]).to eq(:project_value)
      end

      it 'invalidates the cache when project changes' do
        thing.project = :new_project
        allow(Banzai::Renderer).to receive(:cacheless_render_field).and_return(updated_html)

        thing.save

        expect(thing.foo_html).to eq(updated_html)
        expect(thing.baz_html).to eq(updated_html)
        expect(thing.cached_markdown_version).to eq(CacheMarkdownField::CACHE_VERSION)
      end
    end

    context 'with an author' do
      let(:thing) { thing_subclass(:author).new(foo: markdown, foo_html: html, author: :author_value) }

      it 'sets the author in the context' do
        is_expected.to have_key(:author)
        expect(context[:author]).to eq(:author_value)
      end

      it 'invalidates the cache when author changes' do
        thing.author = :new_author
        allow(Banzai::Renderer).to receive(:cacheless_render_field).and_return(updated_html)

        thing.save

        expect(thing.foo_html).to eq(updated_html)
        expect(thing.baz_html).to eq(updated_html)
        expect(thing.cached_markdown_version).to eq(CacheMarkdownField::CACHE_VERSION)
      end
    end
  end
end
