# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Metrics::Sli do
  let(:prometheus) { double("prometheus") }

  before do
    stub_const("Gitlab::Metrics", prometheus)
  end

  describe 'Class methods' do
    it 'does not allow them to be called on the parent module' do
      expect(described_class).not_to respond_to(:[])
      expect(described_class).not_to respond_to(:initialize_sli)
    end

    it 'allows different SLIs to be defined on each subclass' do
      apdex_counters = [
        fake_total_counter('foo_apdex'),
        fake_numerator_counter('foo_apdex', 'success')
      ]

      error_rate_counters = [
        fake_total_counter('foo'),
        fake_numerator_counter('foo', 'error')
      ]

      apdex = described_class::Apdex.initialize_sli(:foo, [{ hello: :world }])

      expect(apdex_counters).to all(have_received(:get).with(hello: :world))

      error_rate = described_class::ErrorRate.initialize_sli(:foo, [{ other: :labels }])

      expect(error_rate_counters).to all(have_received(:get).with(other: :labels))

      expect(described_class::Apdex[:foo]).to be(apdex)
      expect(described_class::ErrorRate[:foo]).to be(error_rate)
    end
  end

  subclasses = {
    Gitlab::Metrics::Sli::Apdex => {
      suffix: '_apdex',
      numerator: :success
    },
    Gitlab::Metrics::Sli::ErrorRate => {
      suffix: '',
      numerator: :error
    }
  }

  subclasses.each do |subclass, subclass_info|
    describe subclass do
      describe 'Class methods' do
        before do
          described_class.instance_variable_set(:@known_slis, nil)
        end

        describe '.[]' do
          it 'returns and stores a new, uninitialized SLI' do
            sli = described_class[:bar]

            expect(described_class[:bar]).to be(sli)
            expect(described_class[:bar]).not_to be_initialized
          end

          it 'returns the same object for multiple accesses' do
            sli = described_class.initialize_sli(:huzzah, [])

            2.times do
              expect(described_class[:huzzah]).to be(sli)
            end
          end
        end

        describe '.initialize_sli' do
          it 'returns and stores a new initialized SLI' do
            counters = [
              fake_total_counter("bar#{subclass_info[:suffix]}"),
              fake_numerator_counter("bar#{subclass_info[:suffix]}", subclass_info[:numerator])
            ]

            sli = described_class.initialize_sli(:bar, [{ hello: :world }])

            expect(sli).to be_initialized
            expect(counters).to all(have_received(:get).with(hello: :world))
            expect(counters).to all(have_received(:get).with(hello: :world))
          end

          it 'does not change labels for an already-initialized SLI' do
            counters = [
              fake_total_counter("bar#{subclass_info[:suffix]}"),
              fake_numerator_counter("bar#{subclass_info[:suffix]}", subclass_info[:numerator])
            ]

            sli = described_class.initialize_sli(:bar, [{ hello: :world }])

            expect(sli).to be_initialized
            expect(counters).to all(have_received(:get).with(hello: :world))
            expect(counters).to all(have_received(:get).with(hello: :world))

            counters.each do |counter|
              expect(counter).not_to receive(:get)
            end

            expect(described_class.initialize_sli(:bar, [{ other: :labels }])).to eq(sli)
          end
        end

        describe '.initialized?' do
          before do
            fake_total_counter("boom#{subclass_info[:suffix]}")
            fake_numerator_counter("boom#{subclass_info[:suffix]}", subclass_info[:numerator])
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
          counters = [
            fake_total_counter("hey#{subclass_info[:suffix]}"),
            fake_numerator_counter("hey#{subclass_info[:suffix]}", subclass_info[:numerator])
          ]

          described_class.new(:hey).initialize_counters([{ foo: 'bar' }, { foo: 'baz' }])

          expect(counters).to all(have_received(:get).with({ foo: 'bar' }))
          expect(counters).to all(have_received(:get).with({ foo: 'baz' }))
        end
      end

      describe "#increment" do
        let!(:sli) { described_class.new(:heyo) }
        let!(:total_counter) { fake_total_counter("heyo#{subclass_info[:suffix]}") }
        let!(:numerator_counter) { fake_numerator_counter("heyo#{subclass_info[:suffix]}", subclass_info[:numerator]) }

        it "increments both counters for labels when #{subclass_info[:numerator]} is true" do
          sli.increment(labels: { hello: "world" }, subclass_info[:numerator] => true)

          expect(total_counter).to have_received(:increment).with({ hello: 'world' })
          expect(numerator_counter).to have_received(:increment).with({ hello: 'world' })
        end

        it "only increments the total counters for labels when #{subclass_info[:numerator]} is false" do
          sli.increment(labels: { hello: "world" }, subclass_info[:numerator] => false)

          expect(total_counter).to have_received(:increment).with({ hello: 'world' })
          expect(numerator_counter).not_to have_received(:increment).with({ hello: 'world' })
        end
      end
    end
  end

  def fake_prometheus_counter(name)
    fake_counter = double("prometheus counter: #{name}")

    allow(fake_counter).to receive(:get)
    allow(fake_counter).to receive(:increment)
    allow(prometheus).to receive(:counter).with(name.to_sym, anything).and_return(fake_counter)

    fake_counter
  end

  def fake_total_counter(name, separator = '_')
    fake_prometheus_counter(['gitlab_sli', name, 'total'].join(separator))
  end

  def fake_numerator_counter(name, numerator_name, separator = '_')
    fake_prometheus_counter(["gitlab_sli", name, "#{numerator_name}_total"].join(separator))
  end
end
