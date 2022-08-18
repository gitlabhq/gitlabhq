# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Git::Conflict::File do
  let(:conflict) { { ancestor: { path: 'ancestor' }, theirs: { path: 'foo', mode: 33188 }, ours: { path: 'foo', mode: 33188 } } }
  let(:invalid_content) { described_class.new(nil, nil, conflict, (+"a\xC4\xFC").force_encoding(Encoding::ASCII_8BIT)) }
  let(:valid_content) { described_class.new(nil, nil, conflict, (+"Espa\xC3\xB1a").force_encoding(Encoding::ASCII_8BIT)) }

  describe '#lines' do
    context 'when the content contains non-UTF-8 characters' do
      it 'raises UnsupportedEncoding' do
        expect { invalid_content.lines }
          .to raise_error(described_class::UnsupportedEncoding)
      end
    end

    context 'when the content can be converted to UTF-8' do
      it 'sets lines to the lines' do
        expect(valid_content.lines).to eq([{
                                             full_line: 'España',
                                             type: nil,
                                             line_obj_index: 0,
                                             line_old: 1,
                                             line_new: 1
                                           }])
      end

      it 'sets the type to text' do
        expect(valid_content.type).to eq('text')
      end
    end
  end

  describe '#content' do
    context 'when the content contains non-UTF-8 characters' do
      it 'raises UnsupportedEncoding' do
        expect { invalid_content.content }
          .to raise_error(described_class::UnsupportedEncoding)
      end
    end

    context 'when the content can be converted to UTF-8' do
      it 'returns a valid UTF-8 string' do
        expect(valid_content.content).to eq('España')
        expect(valid_content.content).to be_valid_encoding
        expect(valid_content.content.encoding).to eq(Encoding::UTF_8)
      end
    end
  end

  describe '#path' do
    it 'returns our_path' do
      expect(valid_content.path).to eq(conflict[:ours][:path])
    end

    context 'when our_path is not present' do
      let(:conflict) { { ancestor: { path: 'ancestor' }, theirs: { path: 'theirs', mode: 33188 }, ours: { path: '', mode: 0 } } }

      it 'returns their_path' do
        expect(valid_content.path).to eq(conflict[:theirs][:path])
      end
    end
  end
end
