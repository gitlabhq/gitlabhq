require 'spec_helper'

describe Banzai::ObjectRenderer do
  let(:project) { create(:empty_project) }
  let(:user) { project.owner }

  def fake_object(attrs = {})
    object = double(attrs.merge("new_record?": true, "destroyed?": true))
    allow(object).to receive(:markdown_cache_field_for).with(:note).and_return(:note_html)
    allow(object).to receive(:banzai_render_context).with(:note).and_return(project: nil, author: nil)
    allow(object).to receive(:update_column).with(:note_html, anything).and_return(true)
    object
  end

  describe '#render' do
    it 'renders and redacts an Array of objects' do
      renderer = described_class.new(project, user)
      object = fake_object(note: 'hello', note_html: nil)

      expect(renderer).to receive(:render_objects).with([object], :note).
        and_call_original

      expect(renderer).to receive(:redact_documents).
        with(an_instance_of(Array)).
        and_call_original

      expect(object).to receive(:redacted_note_html=).with('<p>hello</p>')
      expect(object).to receive(:user_visible_reference_count=).with(0)

      renderer.render([object], :note)
    end
  end

  describe '#render_objects' do
    it 'renders an Array of objects' do
      object = fake_object(note: 'hello', note_html: nil)

      renderer = described_class.new(project, user)

      expect(renderer).to receive(:render_attributes).with([object], :note).
        and_call_original

      rendered = renderer.render_objects([object], :note)

      expect(rendered).to be_an_instance_of(Array)
      expect(rendered[0]).to be_an_instance_of(Nokogiri::HTML::DocumentFragment)
    end
  end

  describe '#redact_documents' do
    it 'redacts a set of documents and returns them as an Array of Hashes' do
      doc = Nokogiri::HTML.fragment('<p>hello</p>')
      renderer = described_class.new(project, user)

      expect_any_instance_of(Banzai::Redactor).to receive(:redact).
        with([doc]).
        and_call_original

      redacted = renderer.redact_documents([doc])

      expect(redacted.count).to eq(1)
      expect(redacted.first[:visible_reference_count]).to eq(0)
      expect(redacted.first[:document].to_html).to eq('<p>hello</p>')
    end
  end

  describe '#context_for' do
    let(:object) { fake_object(note: 'hello') }
    let(:renderer) { described_class.new(project, user) }

    it 'returns a Hash' do
      expect(renderer.context_for(object, :note)).to be_an_instance_of(Hash)
    end

    it 'includes the banzai render context for the object' do
      expect(object).to receive(:banzai_render_context).with(:note).and_return(foo: :bar)
      context = renderer.context_for(object, :note)
      expect(context).to have_key(:foo)
      expect(context[:foo]).to eq(:bar)
    end
  end

  describe '#render_attributes' do
    it 'renders the attribute of a list of objects' do
      objects = [fake_object(note: 'hello', note_html: nil), fake_object(note: 'bye', note_html: nil)]
      renderer = described_class.new(project, user)

      objects.each do |object|
        expect(Banzai).to receive(:render_field).with(object, :note).and_call_original
      end

      docs = renderer.render_attributes(objects, :note)

      expect(docs[0]).to be_an_instance_of(Nokogiri::HTML::DocumentFragment)
      expect(docs[0].to_html).to eq('<p>hello</p>')

      expect(docs[1]).to be_an_instance_of(Nokogiri::HTML::DocumentFragment)
      expect(docs[1].to_html).to eq('<p>bye</p>')
    end

    it 'returns when no objects to render' do
      objects = []
      renderer = described_class.new(project, user, pipeline: :note)

      expect(renderer.render_attributes(objects, :note)).to eq([])
    end
  end

  describe '#base_context' do
    let(:context) do
      described_class.new(project, user, foo: :bar).base_context
    end

    it 'returns a Hash' do
      expect(context).to be_an_instance_of(Hash)
    end

    it 'includes the custom attributes' do
      expect(context[:foo]).to eq(:bar)
    end

    it 'includes the current user' do
      expect(context[:current_user]).to eq(user)
    end

    it 'includes the current project' do
      expect(context[:project]).to eq(project)
    end
  end
end
