# frozen_string_literal: true

require 'spec_helper'

describe BulkInsertSafe do
  class BulkInsertItem < ApplicationRecord
    include BulkInsertSafe
  end

  module InheritedUnsafeMethods
    extend ActiveSupport::Concern

    included do
      after_save -> { "unsafe" }
    end
  end

  module InheritedSafeMethods
    extend ActiveSupport::Concern

    included do
      after_initialize -> { "safe" }
    end
  end

  it_behaves_like 'a BulkInsertSafe model', BulkInsertItem

  context 'when inheriting class methods' do
    it 'raises an error when method is not bulk-insert safe' do
      expect { BulkInsertItem.include(InheritedUnsafeMethods) }.to(
        raise_error(subject::MethodNotAllowedError))
    end

    it 'does not raise an error when method is bulk-insert safe' do
      expect { BulkInsertItem.include(InheritedSafeMethods) }.not_to raise_error
    end
  end
end
