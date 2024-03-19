# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Current, feature_category: :cell do
  describe '#organization=' do
    after do
      described_class.reset
    end

    context 'when organization has not been set yet' do
      where(:value) do
        [nil, '_value_']
      end

      with_them do
        it 'assigns the value and locks the organization setter' do
          expect do
            described_class.organization = value
          end.to change { described_class.lock_organization }.from(nil).to(true)

          expect(described_class.organization).to eq(value)
        end
      end
    end

    context 'when organization has already been set' do
      it 'assigns the value and locks the organization setter' do
        set_value = '_set_value_'

        described_class.organization = set_value

        expect(described_class.lock_organization).to be(true)
        expect(described_class.organization).to eq(set_value)

        expect do
          described_class.organization = '_new_value_'
        end.to raise_error(ArgumentError)

        expect(described_class.organization).to eq(set_value)
      end

      context 'when not raise outside of dev/test environments' do
        before do
          stub_rails_env('production')
        end

        it 'returns silently without changing value' do
          set_value = '_set_value_'

          described_class.organization = set_value

          expect { described_class.organization = '_new_value_' }.not_to raise_error

          expect(described_class.organization).to eq(set_value)
        end
      end
    end
  end
end
