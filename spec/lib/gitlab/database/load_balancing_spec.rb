require 'spec_helper'

describe Gitlab::Database::LoadBalancing do
  describe '.log' do
    it 'logs a message' do
      expect(Rails.logger).to receive(:info).with('boop')

      described_class.log(:info, 'boop')
    end
  end

  describe '.hosts' do
    it 'returns a list of hosts' do
      allow(ActiveRecord::Base.configurations[Rails.env]).to receive(:[])
        .with('load_balancing')
        .and_return({ 'hosts' => %w(foo bar baz) })

      expect(described_class.hosts).to eq(%w(foo bar baz))
    end
  end

  describe '.pool_size' do
    it 'returns a Fixnum' do
      expect(described_class.pool_size).to be_a_kind_of(Integer)
    end
  end

  describe '.enable?' do
    let!(:license) { create(:license, plan: ::License::PREMIUM_PLAN) }

    it 'returns false when no hosts are specified' do
      allow(described_class).to receive(:hosts).and_return([])

      expect(described_class.enable?).to eq(false)
    end

    it 'returns false when Sidekiq is being used' do
      allow(described_class).to receive(:hosts).and_return(%w(foo))
      allow(Sidekiq).to receive(:server?).and_return(true)

      expect(described_class.enable?).to eq(false)
    end

    it 'returns false when a database other than PostgreSQL is being used' do
      allow(described_class).to receive(:hosts).and_return(%w(foo))
      allow(Sidekiq).to receive(:server?).and_return(false)
      allow(Gitlab::Database).to receive(:postgresql?).and_return(false)

      expect(described_class.enable?).to eq(false)
    end

    it 'returns false when running inside a Rake task' do
      expect(described_class).to receive(:program_name).and_return('rake')

      expect(described_class.enable?).to eq(false)
    end

    it 'returns true when load balancing should be enabled' do
      allow(described_class).to receive(:hosts).and_return(%w(foo))
      allow(Sidekiq).to receive(:server?).and_return(false)
      allow(Gitlab::Database).to receive(:postgresql?).and_return(true)

      expect(described_class.enable?).to eq(true)
    end

    context 'without a license' do
      before do
        License.destroy_all
      end

      it 'is disabled' do
        expect(described_class.enable?).to eq(false)
      end
    end

    context 'with an EES license' do
      let!(:license) { create(:license, plan: ::License::STARTER_PLAN) }

      it 'is disabled' do
        expect(described_class.enable?).to eq(false)
      end
    end

    context 'with an EEP license' do
      let!(:license) { create(:license, plan: ::License::PREMIUM_PLAN) }

      it 'is enabled' do
        allow(described_class).to receive(:hosts).and_return(%w(foo))
        allow(Sidekiq).to receive(:server?).and_return(false)
        allow(Gitlab::Database).to receive(:postgresql?).and_return(true)

        expect(described_class.enable?).to eq(true)
      end
    end
  end

  describe '.program_name' do
    it 'returns a String' do
      expect(described_class.program_name).to be_an_instance_of(String)
    end
  end

  describe '.configure_proxy' do
    after do
      described_class.proxy = nil
    end

    it 'configures the connection proxy' do
      expect(ActiveRecord::Base.singleton_class).to receive(:prepend)
        .with(Gitlab::Database::LoadBalancing::ActiveRecordProxy)

      described_class.configure_proxy
    end
  end

  describe '.active_record_models' do
    it 'returns an Array' do
      expect(described_class.active_record_models).to be_an_instance_of(Array)
    end
  end
end
