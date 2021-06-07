# frozen_string_literal: true

RSpec.shared_examples 'a badge template' do |badge_type|
  describe '#key_text' do
    it "says #{badge_type} by default" do
      expect(template.key_text).to eq(badge_type)
    end

    context 'when custom key_text is defined' do
      before do
        allow(badge).to receive(:customization).and_return({ key_text: "custom text" })
      end

      it 'returns custom value' do
        expect(template.key_text).to eq("custom text")
      end

      context 'when its size is larger than the max allowed value' do
        before do
          allow(badge).to receive(:customization).and_return({ key_text: 't' * (::Gitlab::Ci::Badge::Template::MAX_KEY_TEXT_SIZE + 1) } )
        end

        it 'returns default value' do
          expect(template.key_text).to eq(badge_type)
        end
      end
    end
  end

  describe '#key_width' do
    let_it_be(:default_key_width) { ::Gitlab::Ci::Badge::Template::DEFAULT_KEY_WIDTH }

    it 'is fixed by default' do
      expect(template.key_width).to eq(default_key_width)
    end

    context 'when custom key_width is defined' do
      before do
        allow(badge).to receive(:customization).and_return({ key_width: 101 })
      end

      it 'returns custom value' do
        expect(template.key_width).to eq(101)
      end

      context 'when it is larger than the max allowed value' do
        before do
          allow(badge).to receive(:customization).and_return({ key_width: ::Gitlab::Ci::Badge::Template::MAX_KEY_WIDTH + 1 })
        end

        it 'returns default value' do
          expect(template.key_width).to eq(default_key_width)
        end
      end
    end
  end
end
