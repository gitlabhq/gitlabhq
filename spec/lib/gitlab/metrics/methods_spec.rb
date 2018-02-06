require 'spec_helper'

describe Gitlab::Metrics::Methods do
  subject { Class.new { include Gitlab::Metrics::Methods } }

  shared_context 'metric' do |metric_type, *args|
    let(:docstring) { 'description' }
    let(:metric_name) { :sample_metric }

    describe "#define_#{metric_type}" do
      define_method(:call_define_metric_method) do |**args|
        subject.__send__("define_#{metric_type}", metric_name, **args)
      end

      context 'metrics access method not defined' do
        it "defines metrics accessing method" do
          expect(subject).not_to respond_to(metric_name)

          call_define_metric_method(docstring: docstring)

          expect(subject).to respond_to(metric_name)
        end
      end

      context 'metrics access method defined' do
        before do
          call_define_metric_method(docstring: docstring)
        end

        it 'raises error when trying to redefine method' do
          expect { call_define_metric_method(docstring: docstring) }.to raise_error(ArgumentError)
        end

        context 'metric is not cached' do
          it 'calls fetch_metric' do
            expect(subject).to receive(:init_metric).with(metric_type, metric_name, docstring: docstring)

            subject.public_send(metric_name)
          end
        end

        context 'metric is cached' do
          before do
            subject.public_send(metric_name)
          end

          it 'returns cached metric' do
            expect(subject).not_to receive(:init_metric)

            subject.public_send(metric_name)
          end
        end
      end
    end

    describe "#fetch_#{metric_type}" do
      let(:null_metric) { Gitlab::Metrics::NullMetric.instance }

      define_method(:call_fetch_metric_method) do |**args|
        subject.__send__("fetch_#{metric_type}", metric_name, **args)
      end

      context "when #{metric_type} is not cached" do
        it 'initializes counter metric' do
          allow(Gitlab::Metrics).to receive(metric_type).and_return(null_metric)

          call_fetch_metric_method(docstring: docstring)

          expect(Gitlab::Metrics).to have_received(metric_type).with(metric_name, docstring, *args)
        end
      end

      context "when #{metric_type} is cached" do
        before do
          call_fetch_metric_method(docstring: docstring)
        end

        it 'uses class metric cache' do
          expect(Gitlab::Metrics).not_to receive(metric_type)

          call_fetch_metric_method(docstring: docstring)
        end

        context 'when metric is reloaded' do
          before do
            subject.reload_metric!(metric_name)
          end

          it "initializes #{metric_type} metric" do
            allow(Gitlab::Metrics).to receive(metric_type).and_return(null_metric)

            call_fetch_metric_method(docstring: docstring)

            expect(Gitlab::Metrics).to have_received(metric_type).with(metric_name, docstring, *args)
          end
        end
      end

      context 'when metric is configured with feature' do
        let(:feature_name) { :some_metric_feature }
        let(:metric) { call_fetch_metric_method(docstring: docstring, with_feature: feature_name) }

        context 'when feature is enabled' do
          before do
            Feature.get(feature_name).enable
          end

          it "initializes #{metric_type} metric" do
            allow(Gitlab::Metrics).to receive(metric_type).and_return(null_metric)

            metric

            expect(Gitlab::Metrics).to have_received(metric_type).with(metric_name, docstring, *args)
          end
        end

        context 'when feature is disabled' do
          before do
            Feature.get(feature_name).disable
          end

          it "returns NullMetric" do
            allow(Gitlab::Metrics).to receive(metric_type)

            expect(metric).to be_instance_of(Gitlab::Metrics::NullMetric)

            expect(Gitlab::Metrics).not_to have_received(metric_type)
          end
        end
      end
    end
  end

  include_examples 'metric', :counter, {}
  include_examples 'metric', :gauge, {}, :all
  include_examples 'metric', :histogram, {}, [0.005, 0.01, 0.1, 1, 10]
end
