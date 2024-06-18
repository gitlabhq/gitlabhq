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
    expect(instance.cache).to receive(:fetch).with("#{expected_cache_key_prefix}:#{presentable.cache_key}:#{user.cache_key}", expires_in: described_class::DEFAULT_EXPIRY).once

    subject
  end

  context "when a cache context is supplied" do
    before do
      kwargs[:cache_context] = ->(item) { item.project.cache_key }
    end

    it "uses the context to augment the cache key" do
      expect(instance.cache).to receive(:fetch).with("#{expected_cache_key_prefix}:#{presentable.cache_key}:#{project.cache_key}", expires_in: described_class::DEFAULT_EXPIRY).once

      subject
    end
  end

  context "when expires_in is supplied" do
    it "sets the expiry when accessing the cache" do
      kwargs[:expires_in] = 7.days

      expect(instance.cache).to receive(:fetch).with("#{expected_cache_key_prefix}:#{presentable.cache_key}:#{user.cache_key}", expires_in: 7.days).once

      subject
    end
  end

  context 'when a caller id is present' do
    let(:transaction) { Gitlab::Metrics::WebTransaction.new({}) }
    let(:caller_id) { 'caller_id' }

    before do
      allow(::Gitlab::Metrics::WebTransaction).to receive(:current).and_return(transaction)
      allow(transaction).to receive(:increment)
      allow(Gitlab::ApplicationContext).to receive(:current_context_attribute).with(:caller_id).and_return(caller_id)
    end

    it 'increments the counter' do
      expect(transaction)
        .to receive(:increment)
        .with(:cached_object_operations_total, 1, { caller_id: caller_id, render_type: :object, cache_hit: false }).once

      expect(transaction)
        .to receive(:increment)
        .with(:cached_object_operations_total, 0, { caller_id: caller_id, render_type: :object, cache_hit: true }).once

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
    keys = presentable.map { |item| "#{expected_cache_key_prefix}:#{item.cache_key}:#{user.cache_key}" }

    expect(instance.cache).to receive(:fetch_multi).with(*keys, expires_in: described_class::DEFAULT_EXPIRY).once.and_call_original

    subject
  end

  context "when a cache context is supplied" do
    before do
      kwargs[:cache_context] = ->(item) { item.project.cache_key }
    end

    it "uses the context to augment the cache key" do
      keys = presentable.map { |item| "#{expected_cache_key_prefix}:#{item.cache_key}:#{project.cache_key}" }

      expect(instance.cache).to receive(:fetch_multi).with(*keys, expires_in: described_class::DEFAULT_EXPIRY).once.and_call_original

      subject
    end
  end

  context "expires_in is supplied" do
    it "sets the expiry when accessing the cache" do
      keys = presentable.map { |item| "#{expected_cache_key_prefix}:#{item.cache_key}:#{user.cache_key}" }
      kwargs[:expires_in] = 7.days

      expect(instance.cache).to receive(:fetch_multi).with(*keys, expires_in: 7.days).once.and_call_original

      subject
    end
  end

  context 'when a caller id is present' do
    let(:transaction) { Gitlab::Metrics::WebTransaction.new({}) }
    let(:caller_id) { 'caller_id' }

    before do
      allow(::Gitlab::Metrics::WebTransaction).to receive(:current).and_return(transaction)
      allow(transaction).to receive(:increment)
      allow(Gitlab::ApplicationContext).to receive(:current_context_attribute).with(any_args).and_call_original
      allow(Gitlab::ApplicationContext).to receive(:current_context_attribute).with(:caller_id).and_return(caller_id)
    end

    context 'when presentable has a group by clause' do
      let(:presentable) { MergeRequest.group(:id) }

      it "returns the presentables" do
        expect(transaction)
          .to receive(:increment)
          .with(:cached_object_operations_total, 0, { caller_id: caller_id, render_type: :collection, cache_hit: true }).once

        expect(transaction)
          .to receive(:increment)
          .with(:cached_object_operations_total, MergeRequest.count, { caller_id: caller_id, render_type: :collection, cache_hit: false }).once

        parsed = Gitlab::Json.parse(subject.to_s)

        expect(parsed).to be_an(Array)

        presentable.each_with_index do |item, i|
          expect(parsed[i]["id"]).to eq(item.id)
        end
      end
    end

    context 'when the presentables all miss' do
      it 'increments the counters' do
        expect(transaction)
          .to receive(:increment)
          .with(:cached_object_operations_total, 0, { caller_id: caller_id, render_type: :collection, cache_hit: true }).once

        expect(transaction)
          .to receive(:increment)
          .with(:cached_object_operations_total, presentable.size, { caller_id: caller_id, render_type: :collection, cache_hit: false }).once

        subject
      end
    end

    context 'when the presents hit' do
      it 'increments the counters' do
        subject

        expect(transaction)
          .to receive(:increment)
          .with(:cached_object_operations_total, presentable.size, { caller_id: caller_id, render_type: :collection, cache_hit: true }).once

        expect(transaction)
          .to receive(:increment)
          .with(:cached_object_operations_total, 0, { caller_id: caller_id, render_type: :collection, cache_hit: false }).once

        instance.public_send(method, presentable, **kwargs)
      end
    end
  end
end
