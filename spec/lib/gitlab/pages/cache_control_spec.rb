# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::CacheControl, feature_category: :pages do
  describe '.for_namespace' do
    subject(:cache_control) { described_class.for_namespace(1) }

    it { expect(subject.cache_key).to match(/pages_domain_for_namespace_1_*/) }

    describe '#clear_cache' do
      it 'clears the cache' do
        expect(Rails.cache)
          .to receive(:delete_multi)
          .with(
            array_including(
              [
                "pages_domain_for_namespace_1",
                /pages_domain_for_namespace_1_*/
              ]
            ))

        subject.clear_cache
      end
    end
  end

  describe '.for_project' do
    subject(:cache_control) { described_class.for_project(1) }

    it { expect(subject.cache_key).to match(/pages_domain_for_project_1_*/) }

    describe '#clear_cache' do
      it 'clears the cache' do
        expect(Rails.cache)
          .to receive(:delete_multi)
          .with(
            array_including(
              [
                "pages_domain_for_project_1",
                /pages_domain_for_project_1_*/
              ]
            ))

        subject.clear_cache
      end
    end
  end

  describe '#cache_key' do
    it 'does not change the pages config' do
      expect { described_class.new(type: :project, id: 1).cache_key }
        .not_to change(Gitlab.config, :pages)
    end

    it 'is based on pages settings' do
      access_control = Gitlab.config.pages.access_control
      cache_key = described_class.new(type: :project, id: 1).cache_key

      stub_config(pages: { access_control: !access_control })

      expect(described_class.new(type: :project, id: 1).cache_key).not_to eq(cache_key)
    end

    it 'is based on the force_pages_access_control settings' do
      force_pages_access_control = ::Gitlab::CurrentSettings.force_pages_access_control
      cache_key = described_class.new(type: :project, id: 1).cache_key

      ::Gitlab::CurrentSettings.force_pages_access_control = !force_pages_access_control

      expect(described_class.new(type: :project, id: 1).cache_key).not_to eq(cache_key)
    end

    it 'caches the application settings hash' do
      expect(Rails.cache)
        .to receive(:write)
        .with("pages_domain_for_project_1", kind_of(Set))

      described_class.new(type: :project, id: 1).cache_key
    end
  end

  it 'fails with invalid type' do
    expect { described_class.new(type: :unknown, id: nil) }
      .to raise_error(ArgumentError, "type must be :namespace or :project")
  end
end
