# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Symbols::ExtractSymbolSignatureService, feature_category: :package_registry do
  let_it_be(:symbol_file) { fixture_file('packages/nuget/symbol/package.pdb') }

  let(:service) { described_class.new(symbol_file) }

  describe '#execute' do
    subject { service.execute }

    context 'with a valid symbol file' do
      it { expect(subject.payload).to eq('b91a152048fc4b3883bf3cf73fbc03f1FFFFFFFF') }
    end

    context 'with corrupted data' do
      let(:symbol_file) { 'corrupted data' }

      it { expect(subject).to be_error }
    end
  end
end
