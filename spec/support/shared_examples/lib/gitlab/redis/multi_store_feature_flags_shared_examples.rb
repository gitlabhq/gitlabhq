# frozen_string_literal: true

RSpec.shared_examples 'multi store feature flags' do |use_primary_and_secondary_stores, use_primary_store_as_default|
  context "with feature flag :#{use_primary_and_secondary_stores} is enabled" do
    before do
      stub_feature_flags(use_primary_and_secondary_stores => true)
    end

    it 'multi store is enabled' do
      subject.with do |redis_instance|
        expect(redis_instance.use_primary_and_secondary_stores?).to be true
      end
    end
  end

  context "with feature flag :#{use_primary_and_secondary_stores} is disabled" do
    before do
      stub_feature_flags(use_primary_and_secondary_stores => false)
    end

    it 'multi store is disabled' do
      subject.with do |redis_instance|
        expect(redis_instance.use_primary_and_secondary_stores?).to be false
      end
    end
  end

  context "with feature flag :#{use_primary_store_as_default} is enabled" do
    before do
      stub_feature_flags(use_primary_store_as_default => true)
    end

    it 'primary store is enabled' do
      subject.with do |redis_instance|
        expect(redis_instance.use_primary_store_as_default?).to be true
      end
    end
  end

  context "with feature flag :#{use_primary_store_as_default} is disabled" do
    before do
      stub_feature_flags(use_primary_store_as_default => false)
    end

    it 'primary store is disabled' do
      subject.with do |redis_instance|
        expect(redis_instance.use_primary_store_as_default?).to be false
      end
    end
  end
end
