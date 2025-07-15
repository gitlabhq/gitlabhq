# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics, :prometheus, feature_category: :scalability do
  include StubENV

  describe '.settings' do
    it 'returns a Hash' do
      expect(described_class.settings).to be_an_instance_of(Hash)
    end
  end

  describe '.prometheus_metrics_enabled?' do
    subject { described_class.prometheus_metrics_enabled? }

    it { is_expected.to be_in([true, false]) }

    context 'when Gitlab::CurrentSettings.prometheus_metrics_enabled is enabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:prometheus_metrics_enabled).and_return(true)
        Labkit::Metrics::Client.enable!
      end

      it { is_expected.to be true }
    end

    context 'when Gitlab::CurrentSettings.prometheus_metrics_enabled is false' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:prometheus_metrics_enabled).and_return(false)
        Labkit::Metrics::Client.enable!
      end

      it { is_expected.to be false }
    end

    context 'when metrics are disabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:prometheus_metrics_enabled).and_return(true)
        Labkit::Metrics::Client.disable!
      end

      it { is_expected.to be false }
    end
  end

  describe '.measure' do
    context 'without a transaction' do
      it 'returns the return value of the block' do
        val = described_class.measure(:foo) { 10 }

        expect(val).to eq(10)
      end
    end

    context 'with a transaction' do
      let(:transaction) { Gitlab::Metrics::WebTransaction.new({}) }

      before do
        allow(described_class).to receive(:current_transaction)
          .and_return(transaction)
      end

      it 'adds a metric to the current transaction' do
        expect(transaction).to receive(:observe).with(:gitlab_foo_real_duration_seconds, a_kind_of(Numeric))

        expect(transaction).to receive(:observe).with(:gitlab_foo_cpu_duration_seconds, a_kind_of(Numeric))

        described_class.measure(:foo) { 10 }
      end

      it 'returns the return value of the block' do
        val = described_class.measure(:foo) { 10 }

        expect(val).to eq(10)
      end
    end
  end

  describe '#series_prefix' do
    it 'returns a String' do
      expect(described_class.series_prefix).to be_an_instance_of(String)
    end
  end

  describe '.record_status_for_duration?' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :should_record) do
      100  | false
      200  | true
      401  | true
      nil  | false
      500  | false
      503 | false
      'nothing' | false
    end

    with_them do
      specify { expect(described_class.record_duration_for_status?(status)).to be(should_record) }
      specify { expect(described_class.record_duration_for_status?(status.to_s)).to be(should_record) }
    end
  end

  describe '.server_error?' do
    using RSpec::Parameterized::TableSyntax

    where(:status, :should_record) do
      100   | false
      200   | false
      401   | false
      500   | true
      503   | true
      nil   | false
      'nothing' | false
    end

    with_them do
      specify { expect(described_class.server_error?(status)).to be(should_record) }
      specify { expect(described_class.server_error?(status.to_s)).to be(should_record) }
    end
  end

  describe '.add_event' do
    context 'without a transaction' do
      it 'does nothing' do
        expect_any_instance_of(Gitlab::Metrics::Transaction)
          .not_to receive(:add_event)

        described_class.add_event(:meow)
      end
    end

    context 'with a transaction' do
      it 'adds an event' do
        transaction = Gitlab::Metrics::WebTransaction.new({})

        expect(transaction).to receive(:add_event).with(:meow)

        expect(described_class).to receive(:current_transaction)
          .and_return(transaction)

        described_class.add_event(:meow)
      end
    end
  end

  shared_examples 'prometheus metrics API' do
    describe '#counter' do
      subject { described_class.counter(:counter, 'doc') }

      describe '#increment' do
        it 'successfully calls #increment without arguments' do
          expect { subject.increment }.not_to raise_exception
        end

        it 'successfully calls #increment with 1 argument' do
          expect { subject.increment({}) }.not_to raise_exception
        end

        it 'successfully calls #increment with 2 arguments' do
          expect { subject.increment({}, 1) }.not_to raise_exception
        end
      end
    end

    describe '#summary' do
      subject { described_class.summary(:summary, 'doc') }

      describe '#observe' do
        it 'successfully calls #observe with 2 arguments' do
          expect { subject.observe({}, 2) }.not_to raise_exception
        end
      end
    end

    describe '#gauge' do
      subject { described_class.gauge(:gauge, 'doc') }

      describe '#set' do
        it 'successfully calls #set with 2 arguments' do
          expect { subject.set({}, 1) }.not_to raise_exception
        end
      end
    end

    describe '#histogram' do
      subject { described_class.histogram(:histogram, 'doc') }

      describe '#observe' do
        it 'successfully calls #observe with 2 arguments' do
          expect { subject.observe({}, 2) }.not_to raise_exception
        end
      end
    end
  end

  context 'prometheus metrics disabled' do
    before do
      allow(described_class).to receive(:prometheus_metrics_enabled?).and_return(false)
      Labkit::Metrics::Client.disable!
    end

    it_behaves_like 'prometheus metrics API'

    describe '#counter' do
      subject { described_class.counter(:counter, 'doc') }

      it { is_expected.to eq(described_class.null_metric) }
    end

    describe '#summary' do
      subject { described_class.summary(:summary, 'doc') }

      it { is_expected.to eq(described_class.null_metric) }
    end

    describe '#gauge' do
      subject { described_class.gauge(:gauge, 'doc') }

      it { is_expected.to eq(described_class.null_metric) }
    end

    describe '#histogram' do
      subject { described_class.histogram(:histogram, 'doc') }

      it { is_expected.to eq(described_class.null_metric) }
    end
  end

  context 'prometheus metrics enabled' do
    let(:metrics_multiproc_dir) { Dir.mktmpdir }

    before do
      stub_const('Prometheus::Client::Multiprocdir', metrics_multiproc_dir)
      allow(described_class).to receive(:prometheus_metrics_enabled?).and_return(true)
      Labkit::Metrics::Client.enable!
    end

    it_behaves_like 'prometheus metrics API'

    describe '#counter' do
      subject { described_class.counter(:name, 'doc') }

      it { is_expected.not_to eq(described_class.null_metric) }
    end

    describe '#summary' do
      subject { described_class.summary(:name, 'doc') }

      it { is_expected.not_to eq(described_class.null_metric) }
    end

    describe '#gauge' do
      subject { described_class.gauge(:name, 'doc') }

      it { is_expected.not_to eq(described_class.null_metric) }
    end

    describe '#histogram' do
      subject { described_class.histogram(:name, 'doc') }

      it { is_expected.not_to eq(described_class.null_metric) }
    end
  end

  describe '.initialize_slis!', feature_category: :error_budgets do
    let!(:puma_slis) do
      [
        Gitlab::Metrics::RequestsRackMiddleware,
        Gitlab::Metrics::GlobalSearchSlis,
        Gitlab::Metrics::Middleware::PathTraversalCheck
      ]
    end

    let!(:sidekiq_slis) do
      [
        Gitlab::Metrics::Lfs,
        Gitlab::Metrics::LooseForeignKeysSlis
      ]
    end

    context 'when puma runtime' do
      it "initializes only puma SLIs" do
        allow(Gitlab::Runtime).to receive_messages(puma?: true, sidekiq?: false)

        expect(Gitlab::Metrics::SliConfig.enabled_slis).to include(*puma_slis)
        expect(Gitlab::Metrics::SliConfig.enabled_slis).not_to include(*sidekiq_slis)
        expect(Gitlab::Metrics::SliConfig.enabled_slis).to all(receive(:initialize_slis!))

        described_class.initialize_slis!
      end
    end

    context 'when sidekiq runtime' do
      it "initializes only sidekiq SLIs" do
        allow(Gitlab::Runtime).to receive_messages(puma?: false, sidekiq?: true)

        expect(Gitlab::Metrics::SliConfig.enabled_slis).not_to include(*puma_slis)
        expect(Gitlab::Metrics::SliConfig.enabled_slis).to include(*sidekiq_slis)
        expect(Gitlab::Metrics::SliConfig.enabled_slis).to all(receive(:initialize_slis!))

        described_class.initialize_slis!
      end
    end
  end
end
