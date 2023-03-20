# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Rpm::ParsePackageService, feature_category: :package_registry do
  let(:package_file) { File.open('spec/fixtures/packages/rpm/hello-0.0.1-1.fc29.x86_64.rpm') }

  describe 'dynamic private methods' do
    described_class::BUILD_ATTRIBUTES_METHOD_NAMES.each do |attribute|
      it 'define dynamic build attribute method' do
        expect(described_class).to be_private_method_defined("build_#{attribute}")
      end
    end
  end

  describe '#execute' do
    subject { described_class.new(package_file).execute }

    shared_examples 'valid package parsing' do
      it 'return hash' do
        expect(subject).to be_a(Hash)
      end

      it 'has all static attribute keys' do
        expect(subject.keys).to include(*described_class::STATIC_ATTRIBUTES)
      end

      it 'includes epoch attribute' do
        expect(subject[:epoch]).not_to be_blank
      end

      it 'has all built attributes with array values' do
        result = subject
        described_class::BUILD_ATTRIBUTES_METHOD_NAMES.each do |attribute|
          expect(result).to have_key(attribute)
          expect(result[attribute]).to be_a(Array)
        end
      end
    end

    context 'when wrong format file received' do
      let(:package_file) { File.open('spec/fixtures/rails_sample.jpg') }

      it 'raise error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when valid file uploaded' do
      context 'when .rpm file uploaded' do
        it_behaves_like 'valid package parsing'
      end

      context 'when .src.rpm file uploaded' do
        let(:package_file) { File.open('spec/fixtures/packages/rpm/hello-0.0.1-1.fc29.src.rpm') }

        it_behaves_like 'valid package parsing'
      end
    end
  end
end
