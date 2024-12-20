# frozen_string_literal: true

RSpec.shared_examples 'rewrites references correctly' do
  let(:noteable) { source_parent.work_items.first }

  let(:note_params) do
    case source_parent
    when ::Group
      { namespace: source_parent, project: nil }
    when ::Project
      { project: source_parent }
    when ::Namespaces::ProjectNamespace
      { project: source_parent.project }
    end
  end

  let(:note) { create(:note, note: source_text, noteable: noteable, **note_params) }

  it 'checks source and target markdown text', :aggregate_failures do
    new_text = described_class.new(note.note, note.note_html, source_parent, user).rewrite(target_parent)
    source_text_html = generate_html_from_markdown(source_text, source_parent)
    target_text_html = generate_html_from_markdown(destination_text, target_parent)
    source_referable = find_referable(source_text, source_parent, user)
    target_referable = find_referable(new_text, source_parent, user)

    expect(new_text).to eq(destination_text)

    # this checks that the rendered html actually did render, in contrary the result html would look smth like:
    # <p dir="auto">ref #1</p> without an actual link to the referenced object
    expect(source_text_html).to include("href=")
    expect(target_text_html).to include("href=")
    expect(referable_href(source_text_html)).to eq(referable_href(target_text_html))

    # validate that expected referable can be extracted from source and destination texts
    expect(source_referable.id).to eq(target_referable.id)

    # test rewriter with target as project namespace
    if target_parent.is_a?(Project)
      project_namespace = target_parent.project_namespace
      new_text = described_class.new(note.note, note.note_html, source_parent, user).rewrite(project_namespace)

      expect(new_text).to eq(destination_text)
    end

    # test rewriter with source as project namespace
    if source_parent.is_a?(Project)
      project_namespace = source_parent.project_namespace
      new_text = described_class.new(note.note, note.note_html, project_namespace, user).rewrite(target_parent)

      expect(new_text).to eq(destination_text)
    end

    # test rewriter with source and target as project namespace
    if target_parent.is_a?(Project) && source_parent.is_a?(Project)
      target_namespace = target_parent.project_namespace
      source_namespace = source_parent.project_namespace
      new_text = described_class.new(note.note, note.note_html, source_namespace, user).rewrite(target_namespace)

      expect(new_text).to eq(destination_text)
    end
  end
end

RSpec.shared_examples 'does not raise errors on invalid references' do
  let(:noteable) { source_parent.work_items.first }

  let(:note_params) do
    case source_parent
    when ::Group
      { namespace: source_parent, project: nil }
    when ::Project
      { project: source_parent }
    when ::Namespaces::ProjectNamespace
      { project: source_parent.project }
    end
  end

  let(:note) { create(:note, note: text_with_reference, noteable: noteable, **note_params) }

  it 'checks source and target markdown text', :aggregate_failures do
    rewriter = described_class.new(note.note, note.note_html, source_parent, user)
    expect { rewriter.rewrite(target_parent) }.not_to raise_error

    if source_parent.is_a?(Project)
      project_namespace = source_parent.project_namespace
      rewriter = described_class.new(note.note, note.note_html, project_namespace, user)

      expect { rewriter.rewrite(target_parent) }.not_to raise_error
    end

    # test rewriter with source and target as project namespace
    if target_parent.is_a?(Project) && source_parent.is_a?(Project)
      target_namespace = target_parent.project_namespace
      source_namespace = source_parent.project_namespace
      rewriter = described_class.new(note.note, note.note_html, source_namespace, user)

      expect { rewriter.rewrite(target_namespace) }.not_to raise_error
    end
  end
end

def generate_html_from_markdown(text, parent)
  Banzai.render(text, **parent_argument(parent), no_original_data: true, no_sourcepos: true)
end

def parent_argument(parent)
  case parent
  when Project
    { project: parent }
  when Group
    { group: parent, project: nil }
  when Namespaces::ProjectNamespace
    { project: parent.project }
  end
end

def find_referable(reference, parent, user)
  extractor = Gitlab::ReferenceExtractor.new(parent_argument(parent)[:project], user)
  extractor.analyze(reference, **parent_argument(parent))
  extractor.all.first
end

def referable_href(text_html)
  css = 'a'
  xpath = Gitlab::Utils::Nokogiri.css_to_xpath(css)
  Nokogiri::HTML::DocumentFragment.parse(text_html).xpath(xpath).first.attribute('href').value
end
