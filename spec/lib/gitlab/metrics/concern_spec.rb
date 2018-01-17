require 'spec_helper'

describe Gitlab::Metrics::Concern do
  subject { Class.new { include Gitlab::Metrics::Concern } }

  shared_context 'metric' do |metric_type, *args|
    let(:docstring) { 'description' }
    let(:metric) { :sample_metric }

    describe "#define_#{metric_type}" do
      let(:define_method) { "define_#{metric_type}".to_sym }

      context 'metrics access method not defined' do
        it "defines metrics accessing method" do
          expect(subject).not_to respond_to(metric)

          subject.send(define_method, metric, docstring: docstring)

          expect(subject).to respond_to(metric)
        end
      end

      context 'metrics access method defined' do
        before do
          subject.send(define_method, metric, docstring: docstring)
        end

        it 'raises error when trying to redefine method' do
          expect { subject.send(define_method, metric, docstring: docstring) }.to raise_error(ArgumentError)
        end

        context 'metric is not cached' do
          it 'calls fetch_metric' do
            expect(subject).to receive(:fetch_metric).with(metric_type, metric, docstring: docstring)

            subject.send(metric)
          end
        end

        context 'metric is cached' do
          before do
            subject.send(metric)
          end

          it 'returns cached metric' do
            expect(subject).not_to receive(:fetch_metric)

            subject.send(metric)
          end
        end
      end
    end

    describe "#fetch_#{metric_type}" do
      let(:fetch_method) { "fetch_#{metric_type}".to_sym }
      let(:null_metric) { Gitlab::Metrics::NullMetric.new }

      context "when #{metric_type} fetched first time" do
        it 'initializes counter metric' do
          allow(Gitlab::Metrics).to receive(metric_type).and_return(null_metric)

          subject.send(fetch_method, metric, docstring: docstring)

          expect(Gitlab::Metrics).to have_received(metric_type).with(metric, docstring, *args)
        end
      end

      context "when #{metric_type} is fetched second time" do
        before do
          subject.send(fetch_method, metric, docstring: docstring)
        end

        it 'uses class metric cache' do
          expect(Gitlab::Metrics).not_to receive(metric_type)

          subject.send(fetch_method, metric, docstring: docstring)
        end

        context 'when metric is reloaded' do
          before do
            subject.reload_metric!(metric)
          end

          it "initializes #{metric_type} metric" do
            allow(Gitlab::Metrics).to receive(metric_type).and_return(null_metric)

            subject.send(fetch_method, metric, docstring: docstring)

            expect(Gitlab::Metrics).to have_received(metric_type).with(metric, docstring, *args)
          end
        end
      end
    end
  end

  include_examples 'metric', :counter, {}
  include_examples 'metric', :gauge, {}, :all
  include_examples 'metric', :histogram, {}, [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
end
