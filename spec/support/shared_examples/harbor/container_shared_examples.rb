# frozen_string_literal: true

RSpec.shared_examples 'raises NotImplementedError when calling #container' do
  describe '#container' do
    it 'raises NotImplementedError' do
      expect { controller.send(:container) }.to raise_error(NotImplementedError)
    end
  end
end
