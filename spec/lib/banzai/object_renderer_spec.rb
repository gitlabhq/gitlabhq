require 'spec_helper'

describe Banzai::ObjectRenderer do
  let(:project) { create(:empty_project) }
  let(:user) { project.owner }

  describe '#render' do
    it 'renders and redacts an Array of objects' do
      renderer = described_class.new(project, user)
      object = double(:object, note: 'hello', note_html: nil)

      expect(renderer).to receive(:render_objects).with([object], :note).
        and_call_original

      expect(renderer).to receive(:redact_documents).
        with(an_instance_of(Array)).
        and_call_original

      expect(object).to receive(:note_html=).with('<p>hello</p>')

      renderer.render([object], :note)
    end
  end

  describe '#render_objects' do
    it 'renders an Array of objects' do
      object = double(:object, note: 'hello')
      renderer = described_class.new(project, user)

      expect(renderer).to receive(:render_attribute).with(object, :note).
        and_call_original

      rendered = renderer.render_objects([object], :note)

      expect(rendered).to be_an_instance_of(Array)
      expect(rendered[0]).to be_an_instance_of(Nokogiri::HTML::DocumentFragment)
    end
  end

  describe '#redact_documents' do
    it 'redacts a set of documents and returns them as an Array of Strings' do
      doc = Nokogiri::HTML.fragment('<p>hello</p>')
      renderer = described_class.new(project, user)

      expect_any_instance_of(Banzai::Redactor).to receive(:redact).
        with([doc]).
        and_call_original

      redacted = renderer.redact_documents([doc])

      expect(redacted).to eq(['<p>hello</p>'])
    end
  end

  describe '#context_for' do
    let(:object) { double(:object, note: 'hello') }
    let(:renderer) { described_class.new(project, user) }

    it 'returns a Hash' do
      expect(renderer.context_for(object, :note)).to be_an_instance_of(Hash)
    end

    it 'includes the cache key' do
      context = renderer.context_for(object, :note)

      expect(context[:cache_key]).to eq([object, :note])
    end

    context 'when the object responds to "author"' do
      it 'includes the author in the context' do
        expect(object).to receive(:author).and_return('Alice')

        context = renderer.context_for(object, :note)

        expect(context[:author]).to eq('Alice')
      end
    end

    context 'when the object does not respond to "author"' do
      it 'does not include the author in the context' do
        context = renderer.context_for(object, :note)

        expect(context.key?(:author)).to eq(false)
      end
    end
  end

  describe '#render_attribute' do
    it 'renders the attribute of an object' do
      object = double(:doc, note: 'hello')
      renderer = described_class.new(project, user, pipeline: :note)
      doc = renderer.render_attribute(object, :note)

      expect(doc).to be_an_instance_of(Nokogiri::HTML::DocumentFragment)
      expect(doc.to_html).to eq('<p>hello</p>')
    end
  end

  describe '#base_context' do
    let(:context) do
      described_class.new(project, user, pipeline: :note).base_context
    end

    it 'returns a Hash' do
      expect(context).to be_an_instance_of(Hash)
    end

    it 'includes the custom attributes' do
      expect(context[:pipeline]).to eq(:note)
    end

    it 'includes the current user' do
      expect(context[:current_user]).to eq(user)
    end

    it 'includes the current project' do
      expect(context[:project]).to eq(project)
    end
  end
end
