# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab-labkit'

RSpec.describe Gitlab::Metrics::Sli, feature_category: :error_budgets do
  let(:prometheus) { double("prometheus") }

  before do
    stub_const("Gitlab::Metrics", prometheus)
  end

  # TODO: Remove the 'with Labkit implementation' context once we've verified
  # the Labkit SLI implementation works in production and removed the local
  # implementation. At that point, this entire spec can be simplified.
  # See: https://gitlab.com/gitlab-org/ruby/gems/labkit-ruby/-/issues/52
  shared_examples 'sli behavior' do
    describe 'Class methods' do
      it 'does not allow them to be called on the parent module' do
        expect(sli_module).not_to respond_to(:[])
        expect(sli_module).not_to respond_to(:initialize_sli)
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

        apdex = sli_module::Apdex.initialize_sli(:foo, [{ hello: :world }])

        expect(apdex_counters).to all(have_received(:get).with(hello: :world))

        error_rate = sli_module::ErrorRate.initialize_sli(:foo, [{ other: :labels }])

        expect(error_rate_counters).to all(have_received(:get).with(other: :labels))

        expect(sli_module::Apdex[:foo]).to be(apdex)
        expect(sli_module::ErrorRate[:foo]).to be(error_rate)
      end
    end

    subclasses = {
      'Apdex' => {
        suffix: '_apdex',
        numerator: :success
      },
      'ErrorRate' => {
        suffix: '',
        numerator: :error
      }
    }

    subclasses.each do |subclass_name, subclass_info|
      describe subclass_name do
        let(:subclass) { sli_module.const_get(subclass_name, false) }

        describe 'Class methods' do
          before do
            subclass.instance_variable_set(:@known_slis, nil)
          end

          describe '.[]' do
            it 'returns and stores a new, uninitialized SLI' do
              sli = subclass[:bar]

              expect(subclass[:bar]).to be(sli)
              expect(subclass[:bar]).not_to be_initialized
            end

            it 'returns the same object for multiple accesses' do
              sli = subclass.initialize_sli(:huzzah, [])

              2.times do
                expect(subclass[:huzzah]).to be(sli)
              end
            end
          end

          describe '.initialize_sli' do
            it 'returns and stores a new initialized SLI' do
              counters = [
                fake_total_counter("bar#{subclass_info[:suffix]}"),
                fake_numerator_counter("bar#{subclass_info[:suffix]}", subclass_info[:numerator])
              ]

              sli = subclass.initialize_sli(:bar, [{ hello: :world }])

              expect(sli).to be_initialized
              expect(counters).to all(have_received(:get).with(hello: :world))
              expect(counters).to all(have_received(:get).with(hello: :world))
            end

            it 'does not change labels for an already-initialized SLI' do
              counters = [
                fake_total_counter("bar#{subclass_info[:suffix]}"),
                fake_numerator_counter("bar#{subclass_info[:suffix]}", subclass_info[:numerator])
              ]

              sli = subclass.initialize_sli(:bar, [{ hello: :world }])

              expect(sli).to be_initialized
              expect(counters).to all(have_received(:get).with(hello: :world))
              expect(counters).to all(have_received(:get).with(hello: :world))

              counters.each do |counter|
                expect(counter).not_to receive(:get)
              end

              expect(subclass.initialize_sli(:bar, [{ other: :labels }])).to eq(sli)
            end
          end

          describe '.initialized?' do
            before do
              fake_total_counter("boom#{subclass_info[:suffix]}")
              fake_numerator_counter("boom#{subclass_info[:suffix]}", subclass_info[:numerator])
            end

            it 'is true when an SLI was initialized with labels' do
              expect { subclass.initialize_sli(:boom, [{ hello: :world }]) }
                .to change { subclass.initialized?(:boom) }.from(false).to(true)
            end

            it 'is false when an SLI was not initialized with labels' do
              expect { subclass.initialize_sli(:boom, []) }
                .not_to change { subclass.initialized?(:boom) }.from(false)
            end
          end
        end

        describe '#initialize_counters' do
          it 'initializes counters for the passed label combinations' do
            counters = [
              fake_total_counter("hey#{subclass_info[:suffix]}"),
              fake_numerator_counter("hey#{subclass_info[:suffix]}", subclass_info[:numerator])
            ]

            subclass.new(:hey).initialize_counters([{ foo: 'bar' }, { foo: 'baz' }])

            expect(counters).to all(have_received(:get).with({ foo: 'bar' }))
            expect(counters).to all(have_received(:get).with({ foo: 'baz' }))
          end
        end

        describe "#increment" do
          let!(:sli) { subclass.new(:heyo) }
          let!(:total_counter) { fake_total_counter("heyo#{subclass_info[:suffix]}") }
          let!(:numerator_counter) do
            fake_numerator_counter("heyo#{subclass_info[:suffix]}", subclass_info[:numerator])
          end

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
  end

  context 'with local implementation' do
    let(:sli_module) { described_class }

    include_examples 'sli behavior'
  end

  # TODO: Remove this context once we've verified the Labkit SLI implementation
  # works in production and removed the local implementation.
  # See: https://gitlab.com/gitlab-org/ruby/gems/labkit-ruby/-/issues/52
  # This proves that the SLI module quacks the same from Labkit, as it does
  # from Gitlab::Metrics
  context 'with Labkit implementation' do
    let(:sli_module) { Labkit::ApplicationSli }

    before do
      stub_const('Labkit::Metrics::Client', prometheus)
    end

    include_examples 'sli behavior'
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
