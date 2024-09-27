# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Banzai::Pipeline, feature_category: :markdown do
  describe '.[]' do
    subject { described_class[name] }

    shared_examples 'error' do |exception, message|
      it do
        expect { subject }.to raise_error(exception, message)
      end
    end

    context 'for nil' do
      let(:name) { nil }

      it { is_expected.to eq(Banzai::Pipeline::FullPipeline) }
    end

    context 'for symbols' do
      context 'when known' do
        let(:name) { :full }

        it { is_expected.to eq(Banzai::Pipeline::FullPipeline) }
      end

      context 'when unknown' do
        let(:name) { :unknown }

        it_behaves_like 'error', NameError,
          'uninitialized constant Banzai::Pipeline::UnknownPipeline'
      end
    end

    context 'for classes' do
      let(:name) { klass }

      context 'subclassing Banzai::Pipeline::BasePipeline' do
        let(:klass) { Class.new(Banzai::Pipeline::BasePipeline) }

        it { is_expected.to eq(klass) }
      end

      context 'subclassing other types' do
        let(:klass) { Class.new(Banzai::RenderContext) }

        before do
          stub_const('Foo', klass)
        end

        it_behaves_like 'error', ArgumentError,
          'unsupported pipeline name Foo (Class)'
      end
    end

    context 'for other types' do
      let(:name) { 'label' }

      it_behaves_like 'error', ArgumentError,
        'unsupported pipeline name "label" (String)'
    end
  end
end
