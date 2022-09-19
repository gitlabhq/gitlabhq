# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileDownloads::FilenameFetch do
  let(:dummy_instance) { dummy_class.new }
  let(:dummy_class) do
    Class.new do
      include BulkImports::FileDownloads::FilenameFetch
    end
  end

  describe '#raise_error' do
    it { expect { dummy_instance.raise_error('text') }.to raise_exception(NotImplementedError) }
  end
end
