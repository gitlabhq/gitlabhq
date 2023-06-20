# frozen_string_literal: true

require 'spec_helper'

module Dummy
  class Implementation
    include ObjectStorage::FogHelpers

    def storage_location_identifier
      :artifacts
    end
  end

  class WrongImplementation
    include ObjectStorage::FogHelpers
  end
end

RSpec.describe ObjectStorage::FogHelpers, feature_category: :shared do
  let(:implementation_class) { Dummy::Implementation }

  subject { implementation_class.new.available? }

  before do
    stub_artifacts_object_storage(enabled: true)
  end

  describe '#available?' do
    context 'when object storage is enabled' do
      it { is_expected.to eq(true) }
    end

    context 'when object storage is disabled' do
      before do
        stub_artifacts_object_storage(enabled: false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when implementing class did not define storage_location_identifier' do
      let(:implementation_class) { Dummy::WrongImplementation }

      it 'raises an error' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end
end
