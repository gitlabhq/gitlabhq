# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Pipeline::Context do
  describe '#initialize' do
    it 'initializes with permitted attributes' do
      args = {
        current_user: create(:user),
        entity: create(:bulk_import_entity),
        configuration: create(:bulk_import_configuration)
      }

      context = described_class.new(args)

      args.each do |k, v|
        expect(context.public_send(k)).to eq(v)
      end
    end

    context 'when invalid argument is passed' do
      it 'raises NoMethodError' do
        expect { described_class.new(test: 'test').test }.to raise_exception(NoMethodError)
      end
    end
  end
end
