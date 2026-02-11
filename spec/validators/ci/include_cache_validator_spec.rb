# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::IncludeCacheValidator, feature_category: :pipeline_composition do
  # rubocop:disable RSpec/VerifiedDoubles -- No actual record class to verify against
  let(:validator) { described_class.new(attributes: [:cache]) }
  let(:record) { double('record', config: config, errors: errors) }
  let(:errors) { double('errors') }
  let(:attribute) { :cache }

  describe '#validate_each' do
    context 'when value is blank' do
      let(:config) { { remote: 'https://example.com/file.yml' } }

      it 'does not validate' do
        expect(errors).not_to receive(:add)

        validator.validate_each(record, attribute, nil)
      end
    end

    context 'when value is present' do
      let(:config) { { remote: 'https://example.com/file.yml' } }

      context 'with valid boolean value' do
        it 'does not add errors' do
          expect(errors).not_to receive(:add)

          validator.validate_each(record, attribute, true)
        end
      end

      context 'with valid duration string' do
        it 'does not add errors' do
          expect(errors).not_to receive(:add)

          validator.validate_each(record, attribute, '1 day')
        end
      end
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles
end
