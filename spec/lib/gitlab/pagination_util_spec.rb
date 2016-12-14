require 'spec_helper'

describe Gitlab::PaginationUtil, lib: true do
  context 'class with no pagination delegate defined' do
    let(:pagination_class) { Class.new { extend Gitlab::PaginationUtil } }

    it 'throws an error calling the method' do
      expect { pagination_class.pagination_delegate }.to raise_error(NotImplementedError)
    end
  end

  context 'class with no pagination delegate defined' do
    let(:pagination_class) { Class.new { extend Gitlab::PaginationUtil } }
    let(:pagination_delegate) do
      Gitlab::PaginationDelegate.new(page: 1,
                                     per_page: 10,
                                     count: 20)
    end

    let(:delegated_methods) { %i[total_count total_pages current_page limit_value first_page? prev_page last_page? next_page] }

    before do
      allow(pagination_class).to receive(:pagination_delegate).and_return(pagination_delegate)
    end

    it 'does not throw an error' do
      expect { pagination_class.pagination_delegate }.not_to raise_error
    end

    it 'includes the delegated methods' do
      expect(pagination_class.public_methods).to include(*delegated_methods)
    end
  end
end
