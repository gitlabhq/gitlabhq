# frozen_string_literal: true

RSpec.shared_examples_for 'object cache helper' do
  it { is_expected.to be_a(Gitlab::Json::PrecompiledJson) }

  it "uses the presenter" do
    expect(presenter).to receive(:represent).with(presentable, project: project)

    subject
  end

  it "is valid JSON" do
    parsed = Gitlab::Json.parse(subject.to_s)

    expect(parsed).to be_a(Hash)
    expect(parsed["id"]).to eq(presentable.id)
  end

  it "fetches from the cache" do
    expect(instance.cache).to receive(:fetch).with("#{presenter.class.name}:#{presentable.cache_key}:#{user.cache_key}", expires_in: described_class::DEFAULT_EXPIRY).once

    subject
  end

  context "when a cache context is supplied" do
    before do
      kwargs[:cache_context] = -> (item) { item.project.cache_key }
    end

    it "uses the context to augment the cache key" do
      expect(instance.cache).to receive(:fetch).with("#{presenter.class.name}:#{presentable.cache_key}:#{project.cache_key}", expires_in: described_class::DEFAULT_EXPIRY).once

      subject
    end
  end

  context "when expires_in is supplied" do
    it "sets the expiry when accessing the cache" do
      kwargs[:expires_in] = 7.days

      expect(instance.cache).to receive(:fetch).with("#{presenter.class.name}:#{presentable.cache_key}:#{user.cache_key}", expires_in: 7.days).once

      subject
    end
  end
end

RSpec.shared_examples_for 'collection cache helper' do
  it { is_expected.to be_an(Gitlab::Json::PrecompiledJson) }

  it "uses the presenter" do
    presentable.each do |item|
      expect(presenter).to receive(:represent).with(item, project: project)
    end

    subject
  end

  it "is valid JSON" do
    parsed = Gitlab::Json.parse(subject.to_s)

    expect(parsed).to be_an(Array)

    presentable.each_with_index do |item, i|
      expect(parsed[i]["id"]).to eq(item.id)
    end
  end

  it "fetches from the cache" do
    keys = presentable.map { |item| "#{presenter.class.name}:#{item.cache_key}:#{user.cache_key}" }

    expect(instance.cache).to receive(:fetch_multi).with(*keys, expires_in: described_class::DEFAULT_EXPIRY).once.and_call_original

    subject
  end

  context "when a cache context is supplied" do
    before do
      kwargs[:cache_context] = -> (item) { item.project.cache_key }
    end

    it "uses the context to augment the cache key" do
      keys = presentable.map { |item| "#{presenter.class.name}:#{item.cache_key}:#{project.cache_key}" }

      expect(instance.cache).to receive(:fetch_multi).with(*keys, expires_in: described_class::DEFAULT_EXPIRY).once.and_call_original

      subject
    end
  end

  context "expires_in is supplied" do
    it "sets the expiry when accessing the cache" do
      keys = presentable.map { |item| "#{presenter.class.name}:#{item.cache_key}:#{user.cache_key}" }
      kwargs[:expires_in] = 7.days

      expect(instance.cache).to receive(:fetch_multi).with(*keys, expires_in: 7.days).once.and_call_original

      subject
    end
  end
end
