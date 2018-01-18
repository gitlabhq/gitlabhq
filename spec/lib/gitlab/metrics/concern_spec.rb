require 'spec_helper'

describe Gitlab::Metrics::Concern do
  subject { Class.new { include Gitlab::Metrics::Concern } }

  shared_context 'metric' do |metric_type, *args|
    let(:docstring) { 'description' }
    let(:metric_name) { :sample_metric }

    describe "#define_#{metric_type}" do
      let(:define_method) { "define_#{metric_type}".to_sym }

      context 'metrics access method not defined' do
        it "defines metrics accessing method" do
          expect(subject).not_to respond_to(metric_name)

          subject.send(define_method, metric_name, docstring: docstring)

          expect(subject).to respond_to(metric_name)
        end
      end

      context 'metrics access method defined' do
        before do
          subject.send(define_method, metric_name, docstring: docstring)
        end

        it 'raises error when trying to redefine method' do
          expect { subject.send(define_method, metric_name, docstring: docstring) }.to raise_error(ArgumentError)
        end

        context 'metric is not cached' do
          it 'calls fetch_metric' do
            expect(subject).to receive(:fetch_metric).with(metric_type, metric_name, docstring: docstring)

            subject.send(metric_name)
          end
        end

        context 'metric is cached' do
          before do
            subject.send(metric_name)
          end

          it 'returns cached metric' do
            expect(subject).not_to receive(:fetch_metric)

            subject.send(metric_name)
          end
        end
      end
    end

    describe "#fetch_#{metric_type}" do
      let(:fetch_method) { "fetch_#{metric_type}".to_sym }
      let(:null_metric) { Gitlab::Metrics::NullMetric.new }

      context "when #{metric_type} is not cached" do
        it 'initializes counter metric' do
          allow(Gitlab::Metrics).to receive(metric_type).and_return(null_metric)

          subject.send(fetch_method, metric_name, docstring: docstring)

          expect(Gitlab::Metrics).to have_received(metric_type).with(metric_name, docstring, *args)
        end
      end

      context "when #{metric_type} is cached" do
        before do
          subject.send(fetch_method, metric_name, docstring: docstring)
        end

        it 'uses class metric cache' do
          expect(Gitlab::Metrics).not_to receive(metric_type)

          subject.send(fetch_method, metric_name, docstring: docstring)
        end

        context 'when metric is reloaded' do
          before do
            subject.reload_metric!(metric_name)
          end

          it "initializes #{metric_type} metric" do
            allow(Gitlab::Metrics).to receive(metric_type).and_return(null_metric)

            subject.send(fetch_method, metric_name, docstring: docstring)

            expect(Gitlab::Metrics).to have_received(metric_type).with(metric_name, docstring, *args)
          end
        end
      end

      context 'when metric is configured with feature' do
        let(:feature_name) { :some_metric_feature }
        let(:metric) { subject.send(fetch_method, metric_name, docstring: docstring, with_feature: feature_name) }

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
            allow(Gitlab::Metrics).to receive(metric_type).and_return(null_metric)

            expect(metric).to be_instance_of(Gitlab::Metrics::NullMetric)

            expect(Gitlab::Metrics).not_to have_received(metric_type)
          end
        end
      end
    end
  end

  include_examples 'metric', :counter, {}
  include_examples 'metric', :gauge, {}, :all
  include_examples 'metric', :histogram, {}, [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
end
