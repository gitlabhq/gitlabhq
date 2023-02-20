# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::CacheControl, feature_category: :pages do
  RSpec.shared_examples 'cache_control' do |type|
    it { expect(subject.cache_key).to match(/pages_domain_for_#{type}_1_*/) }

    describe '#clear_cache', :use_clean_rails_redis_caching do
      before do
        Rails.cache.write("pages_domain_for_#{type}_1", ['settings-hash'])
        Rails.cache.write("pages_domain_for_#{type}_1_settings-hash", 'payload')
      end

      it 'clears the cache' do
        cached_keys = [
          "pages_domain_for_#{type}_1_settings-hash",
          "pages_domain_for_#{type}_1"
        ]

        expect(::Gitlab::AppLogger)
          .to receive(:info)
          .with(
            message: 'clear pages cache',
            pages_keys: cached_keys,
            pages_type: type,
            pages_id: 1
          )

        expect(Rails.cache)
          .to receive(:delete_multi)
          .with(cached_keys)

        subject.clear_cache
      end
    end
  end

  describe '.for_namespace' do
    subject(:cache_control) { described_class.for_namespace(1) }

    it_behaves_like 'cache_control', :namespace
  end

  describe '.for_domain' do
    subject(:cache_control) { described_class.for_domain(1) }

    it_behaves_like 'cache_control', :domain
  end

  describe '#cache_key' do
    it 'does not change the pages config' do
      expect { described_class.new(type: :domain, id: 1).cache_key }
        .not_to change(Gitlab.config, :pages)
    end

    it 'is based on pages settings' do
      access_control = Gitlab.config.pages.access_control
      cache_key = described_class.new(type: :domain, id: 1).cache_key

      stub_config(pages: { access_control: !access_control })

      expect(described_class.new(type: :domain, id: 1).cache_key).not_to eq(cache_key)
    end

    it 'is based on the force_pages_access_control settings' do
      force_pages_access_control = ::Gitlab::CurrentSettings.force_pages_access_control
      cache_key = described_class.new(type: :domain, id: 1).cache_key

      ::Gitlab::CurrentSettings.force_pages_access_control = !force_pages_access_control

      expect(described_class.new(type: :domain, id: 1).cache_key).not_to eq(cache_key)
    end

    it 'caches the application settings hash' do
      expect(Rails.cache)
        .to receive(:write)
        .with('pages_domain_for_domain_1', kind_of(Set))

      described_class.new(type: :domain, id: 1).cache_key
    end
  end

  it 'fails with invalid type' do
    expect { described_class.new(type: :unknown, id: nil) }
      .to raise_error(ArgumentError, 'type must be :namespace or :domain')
  end
end
