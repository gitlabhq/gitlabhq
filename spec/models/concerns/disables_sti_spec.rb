# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DisablesSti, feature_category: :shared do
  describe '#new' do
    context 'for a non STI class like Project' do
      it 'can initialize' do
        expect { Project.new }.not_to raise_error
      end
    end

    context 'for a base class which has an inheritance column' do
      it 'can initialize' do
        expect { Label.new }.not_to raise_error
      end
    end

    context 'for an STI class that previously existed' do
      it 'can initialize' do
        expect { GroupLabel.new }.not_to raise_error
      end
    end

    context 'for an STI class that is new' do
      before do
        stub_const('DummyModel', Class.new(Label))
      end

      it 'cannot initialize' do
        expect { DummyModel.new }.to raise_error(/Do not use Single Table Inheritance/)
      end

      context 'when SKIP_STI_CHECK is true' do
        before do
          stub_const("#{described_class}::SKIP_STI_CHECK", 'true')
        end

        it 'can initialize' do
          expect { DummyModel.new }.not_to raise_error
        end
      end
    end

    context 'for an STI class descending from Integration' do
      before do
        stub_const('IntegrationDummyModel', Class.new(Integration))
      end

      it 'can initialize' do
        expect { IntegrationDummyModel.new }.not_to raise_error
      end
    end
  end
end
