# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Metrics::Sli do
  let(:prometheus) { double("prometheus") }

  before do
    stub_const("Gitlab::Metrics", prometheus)
  end

  describe 'Class methods' do
    before do
      described_class.instance_variable_set(:@known_slis, nil)
    end

    describe '.[]' do
      it 'warns about an uninitialized SLI but returns and stores a new one' do
        sli = described_class[:bar]

        expect(described_class[:bar]).to be(sli)
      end

      it 'returns the same object for multiple accesses' do
        sli = described_class.initialize_sli(:huzzah, [])

        2.times do
          expect(described_class[:huzzah]).to be(sli)
        end
      end
    end

    describe '.initialized?' do
      before do
        fake_total_counter(:boom)
        fake_success_counter(:boom)
      end

      it 'is true when an SLI was initialized with labels' do
        expect { described_class.initialize_sli(:boom, [{ hello: :world }]) }
          .to change { described_class.initialized?(:boom) }.from(false).to(true)
      end

      it 'is false when an SLI was not initialized with labels' do
        expect { described_class.initialize_sli(:boom, []) }
          .not_to change { described_class.initialized?(:boom) }.from(false)
      end
    end
  end

  describe '#initialize_counters' do
    it 'initializes counters for the passed label combinations' do
      counters = [fake_total_counter(:hey), fake_success_counter(:hey)]

      described_class.new(:hey).initialize_counters([{ foo: 'bar' }, { foo: 'baz' }])

      expect(counters).to all(have_received(:get).with({ foo: 'bar' }))
      expect(counters).to all(have_received(:get).with({ foo: 'baz' }))
    end
  end

  describe "#increment" do
    let!(:sli) { described_class.new(:heyo) }
    let!(:total_counter) { fake_total_counter(:heyo) }
    let!(:success_counter) { fake_success_counter(:heyo) }

    it 'increments both counters for labels successes' do
      sli.increment(labels: { hello: "world" }, success: true)

      expect(total_counter).to have_received(:increment).with({ hello: 'world' })
      expect(success_counter).to have_received(:increment).with({ hello: 'world' })
    end

    it 'only increments the total counters for labels when not successful' do
      sli.increment(labels: { hello: "world" }, success: false)

      expect(total_counter).to have_received(:increment).with({ hello: 'world' })
      expect(success_counter).not_to have_received(:increment).with({ hello: 'world' })
    end
  end

  def fake_prometheus_counter(name)
    fake_counter = double("prometheus counter: #{name}")

    allow(fake_counter).to receive(:get)
    allow(fake_counter).to receive(:increment)
    allow(prometheus).to receive(:counter).with(name.to_sym, anything).and_return(fake_counter)

    fake_counter
  end

  def fake_total_counter(name)
    fake_prometheus_counter("gitlab_sli:#{name}:total")
  end

  def fake_success_counter(name)
    fake_prometheus_counter("gitlab_sli:#{name}:success_total")
  end
end
