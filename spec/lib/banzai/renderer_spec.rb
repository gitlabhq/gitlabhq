require 'spec_helper'

describe Banzai::Renderer do
  def fake_object(fresh:)
    object = double('object')

    allow(object).to receive(:cached_html_up_to_date?).with(:field).and_return(fresh)
    allow(object).to receive(:cached_html_for).with(:field).and_return('field_html')

    object
  end

  describe '#render_field' do
    let(:renderer) { Banzai::Renderer }
    subject { renderer.render_field(object, :field) }

    context "with an empty cache" do
      let(:object) { fake_object(:markdown) }
      it "caches and returns the result" do
        expect_render
        expect_cache_update
        expect(subject).to eq(:html)
      end

      it "skips database caching on a Geo secondary" do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
        expect_render
        expect_cache_update.never
        expect(subject).to eq(:html)
      end
    end

    context 'with a stale cache' do
      let(:object) { fake_object(fresh: false) }

      it 'caches and returns the result' do
        expect(object).to receive(:refresh_markdown_cache!).with(do_update: true)

        is_expected.to eq('field_html')
      end
    end

    context 'with an up-to-date cache' do
      let(:object) { fake_object(fresh: true) }

      it 'uses the cache' do
        expect(object).to receive(:refresh_markdown_cache!).never

        is_expected.to eq('field_html')
      end
    end
  end
end
