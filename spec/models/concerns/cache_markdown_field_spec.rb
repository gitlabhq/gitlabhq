require 'spec_helper'

describe CacheMarkdownField do
  CacheMarkdownField::CACHING_CLASSES << "ThingWithMarkdownFields"

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
    define_model_callbacks :save

    include CacheMarkdownField
    cache_markdown_field :foo
    cache_markdown_field :baz, pipeline: :single_line

    def self.add_attr(attr_name)
      self.attribute_names += [attr_name]
      define_attribute_methods(attr_name)
      attr_reader(attr_name)
      define_method("#{attr_name}=") do |val|
        send("#{attr_name}_will_change!") unless val == send(attr_name)
        instance_variable_set("@#{attr_name}", val)
      end
    end

    [:foo, :foo_html, :bar, :baz, :baz_html].each do |attr_name|
      add_attr(attr_name)
    end

    def initialize(*)
      super

      # Pretend new is load
      clear_changes_information
    end

    def save
      run_callbacks :save do
        changes_applied
      end
    end
  end

  CacheMarkdownField::CACHING_CLASSES.delete("ThingWithMarkdownFields")

  def thing_subclass(new_attr)
    Class.new(ThingWithMarkdownFields) { add_attr(new_attr) }
  end

  let(:markdown) { "`Foo`" }
  let(:html) { "<p><code>Foo</code></p>" }

  let(:updated_markdown) { "`Bar`" }
  let(:updated_html) { "<p><code>Bar</code></p>" }

  subject { ThingWithMarkdownFields.new(foo: markdown, foo_html: html) }

  describe ".attributes" do
    it "excludes cache attributes" do
      expect(thing_subclass(:qux).new.attributes.keys.sort).to eq(%w[bar baz foo qux])
    end
  end

  describe ".cache_markdown_field" do
    it "refuses to allow untracked classes" do
      expect { thing_subclass(:qux).__send__(:cache_markdown_field, :qux) }.to raise_error(RuntimeError)
    end
  end

  context "an unchanged markdown field" do
    before do
      subject.foo = subject.foo
      subject.save
    end

    it { expect(subject.foo).to eq(markdown) }
    it { expect(subject.foo_html).to eq(html) }
    it { expect(subject.foo_html_changed?).not_to be_truthy }
  end

  context "a changed markdown field" do
    before do
      subject.foo = updated_markdown
      subject.save
    end

    it { expect(subject.foo_html).to eq(updated_html) }
  end

  context "a non-markdown field changed" do
    before do
      subject.bar = "OK"
      subject.save
    end

    it { expect(subject.bar).to eq("OK") }
    it { expect(subject.foo).to eq(markdown) }
    it { expect(subject.foo_html).to eq(html) }
  end

  describe '#banzai_render_context' do
    it "sets project to nil if the object lacks a project" do
      context = subject.banzai_render_context(:foo)
      expect(context).to have_key(:project)
      expect(context[:project]).to be_nil
    end

    it "excludes author if the object lacks an author" do
      context = subject.banzai_render_context(:foo)
      expect(context).not_to have_key(:author)
    end

    it "raises if the context for an unrecognised field is requested" do
      expect{subject.banzai_render_context(:not_found)}.to raise_error(ArgumentError)
    end

    it "includes the pipeline" do
      context = subject.banzai_render_context(:baz)
      expect(context[:pipeline]).to eq(:single_line)
    end

    it "returns copies of the context template" do
      template = subject.cached_markdown_fields[:baz]
      copy = subject.banzai_render_context(:baz)
      expect(copy).not_to be(template)
    end

    context "with a project" do
      subject { thing_subclass(:project).new(foo: markdown, foo_html: html, project: :project) }

      it "sets the project in the context" do
        context = subject.banzai_render_context(:foo)
        expect(context).to have_key(:project)
        expect(context[:project]).to eq(:project)
      end

      it "invalidates the cache when project changes" do
        subject.project = :new_project
        allow(Banzai::Renderer).to receive(:cacheless_render_field).and_return(updated_html)

        subject.save

        expect(subject.foo_html).to eq(updated_html)
        expect(subject.baz_html).to eq(updated_html)
      end
    end

    context "with an author" do
      subject { thing_subclass(:author).new(foo: markdown, foo_html: html, author: :author) }

      it "sets the author in the context" do
        context = subject.banzai_render_context(:foo)
        expect(context).to have_key(:author)
        expect(context[:author]).to eq(:author)
      end

      it "invalidates the cache when author changes" do
        subject.author = :new_author
        allow(Banzai::Renderer).to receive(:cacheless_render_field).and_return(updated_html)

        subject.save

        expect(subject.foo_html).to eq(updated_html)
        expect(subject.baz_html).to eq(updated_html)
      end
    end
  end
end
