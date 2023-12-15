# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::Representable, feature_category: :importers do
  let(:representation_class) do
    subject_module = described_class

    Class.new do
      include subject_module
    end
  end

  let(:representable) { representation_class.new }

  describe '#github_identifiers' do
    subject(:github_identifiers) { representable.github_identifiers }

    context 'when class does not define `#github_identifiers`' do
      it 'tracks the error' do
        error = NotImplementedError.new('Subclasses must implement #github_identifiers')

        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(error)
        is_expected.to eq({})
      end
    end

    context 'when class defines `#github_identifiers`' do
      let(:representation_class) do
        Class.new(super()) do
          def github_identifiers
            { id: 1 }
          end
        end
      end

      it 'does not track an exception and returns the identifiers' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)
        is_expected.to eq({ id: 1 })
      end
    end
  end
end
