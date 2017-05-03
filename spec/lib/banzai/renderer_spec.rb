require 'spec_helper'

describe Banzai::Renderer do
  def fake_object(fresh:)
    object = double('object')

    allow(object).to receive(:cached_html_up_to_date?).with(:field).and_return(fresh)
    allow(object).to receive(:cached_html_for).with(:field).and_return('field_html')

    object
  end

  describe '#render_field' do
    let(:renderer) { described_class }
    subject { renderer.render_field(object, :field) }

    context 'with a stale cache' do
      let(:object) { fake_object(fresh: false) }

      it 'caches and returns the result' do
        expect(object).to receive(:refresh_markdown_cache!).with(do_update: true)

        is_expected.to eq('field_html')
      end

      it "skips database caching on a Geo secondary" do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
        expect(object).to receive(:refresh_markdown_cache!).with(do_update: false)

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
