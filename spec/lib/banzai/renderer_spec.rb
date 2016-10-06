require 'spec_helper'

describe Banzai::Renderer do
  def expect_render(project = :project)
    expected_context = { project: project }
    expect(renderer).to receive(:cacheless_render) { :html }.with(:markdown, expected_context)
  end

  def expect_cache_update
    expect(object).to receive(:update_column).with("field_html", :html)
  end

  def fake_object(*features)
    markdown = :markdown if features.include?(:markdown)
    html = :html if features.include?(:html)

    object = double(
      "object",
      banzai_render_context: { project: :project },
      field: markdown,
      field_html: html
    )

    allow(object).to receive(:markdown_cache_field_for).with(:field).and_return("field_html")
    allow(object).to receive(:new_record?).and_return(features.include?(:new))
    allow(object).to receive(:destroyed?).and_return(features.include?(:destroyed))

    object
  end

  describe "#render_field" do
    let(:renderer) { Banzai::Renderer }
    let(:subject) { renderer.render_field(object, :field) }

    context "with an empty cache" do
      let(:object) { fake_object(:markdown) }
      it "caches and returns the result" do
        expect_render
        expect_cache_update
        expect(subject).to eq(:html)
      end
    end

    context "with a filled cache" do
      let(:object) { fake_object(:markdown, :html) }

      it "uses the cache" do
        expect_render.never
        expect_cache_update.never
        should eq(:html)
      end
    end

    context "new object" do
      let(:object) { fake_object(:new, :markdown) }

      it "doesn't cache the result" do
        expect_render
        expect_cache_update.never
        expect(subject).to eq(:html)
      end
    end

    context "destroyed object" do
      let(:object) { fake_object(:destroyed, :markdown) }

      it "doesn't cache the result" do
        expect_render
        expect_cache_update.never
        expect(subject).to eq(:html)
      end
    end
  end
end
