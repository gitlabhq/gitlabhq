# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::CacheControl do
  it 'fails with invalid type' do
    expect { described_class.new(type: :unknown, id: nil) }
      .to raise_error(ArgumentError, "type must be :namespace or :project")
  end

  describe '.for_namespace' do
    let(:subject) { described_class.for_namespace(1) }

    it { expect(subject.cache_key).to eq('pages_domain_for_namespace_1') }

    describe '#clear_cache' do
      it 'clears the cache' do
        expect(Rails.cache)
          .to receive(:delete)
          .with('pages_domain_for_namespace_1')

        subject.clear_cache
      end
    end
  end

  describe '.for_project' do
    let(:subject) { described_class.for_project(1) }

    it { expect(subject.cache_key).to eq('pages_domain_for_project_1') }

    describe '#clear_cache' do
      it 'clears the cache' do
        expect(Rails.cache)
          .to receive(:delete)
          .with('pages_domain_for_project_1')

        subject.clear_cache
      end
    end
  end
end
