# frozen_string_literal: true

require 'fast_spec_helper'
require 'rake'

require_relative '../../../../tooling/lib/tooling/rake_announcer'

RSpec.describe Tooling::RakeAnnouncer, feature_category: :tooling do
  describe '.should_run?' do
    subject(:should_run) { described_class.should_run? }

    before do
      allow(described_class).to receive(:args).and_return(['db:migrate:up'])
      allow(ENV).to receive(:key?).and_call_original
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
    end

    context 'when CI env var is set' do
      before do
        allow(ENV).to receive(:key?).with('CI').and_return(true)
      end

      it { is_expected.to be(false) }
    end

    context 'when not in CI' do
      before do
        allow(ENV).to receive(:key?).with('CI').and_return(false)
      end

      context 'when not in development environment' do
        before do
          allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('test'))
        end

        it { is_expected.to be(false) }
      end

      context 'when in development environment' do
        context 'when no db:migrate: args are present' do
          before do
            allow(described_class).to receive(:args).and_return(['spec', 'db:seed'])
          end

          it { is_expected.to be(false) }
        end

        context 'when a db:migrate: arg is present' do
          before do
            allow(described_class).to receive(:args).and_return(['db:migrate:up'])
          end

          it { is_expected.to be(true) }
        end
      end
    end
  end

  describe '.args' do
    subject(:args) { described_class.args }

    context 'when invoked via rails' do
      before do
        allow(Process).to receive(:argv0).and_return('/usr/local/bin/rails')
        allow(Rake.application).to receive(:top_level_tasks).and_return(['db:migrate:up'])
      end

      it { is_expected.to eq(['db:migrate:up']) }
    end

    context 'when not invoked via rails' do
      before do
        allow(Process).to receive(:argv0).and_return('/usr/local/bin/rake')
        stub_const('ARGV', ['db:migrate:status'])
      end

      it { is_expected.to eq(['db:migrate:status']) }
    end
  end

  describe '.run' do
    context 'when should_run? is false' do
      before do
        allow(described_class).to receive(:should_run?).and_return(false)
      end

      it 'does not register an at_exit hook' do
        expect(described_class).not_to receive(:at_exit)

        described_class.run
      end
    end

    context 'when should_run? is true' do
      before do
        allow(described_class).to receive(:should_run?).and_return(true)
      end

      it 'registers an at_exit hook' do
        expect(described_class).to receive(:at_exit)

        described_class.run
      end
    end
  end
end
