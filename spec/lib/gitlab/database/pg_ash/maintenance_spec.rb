# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PgAsh::Maintenance, feature_category: :database do
  let(:conn) { ActiveRecord::Base.connection }

  subject(:maintenance) { described_class.new(conn) }

  describe '#run' do
    before do
      allow(Gitlab::Database::PgAsh).to receive(:execute).and_return([{ 'result' => 3 }])
    end

    described_class::TASKS.each do |task|
      it "calls ash.#{task}() on the primary and returns what it reported" do
        expect(Gitlab::Database::LoadBalancing::SessionMap.current(conn.load_balancer))
          .to receive(:use_primary).and_call_original

        expect(maintenance.run(task)).to eq('3')
        expect(Gitlab::Database::PgAsh).to have_received(:execute).with(conn, "SELECT ash.#{task}() AS result")
      end
    end

    it 'accepts the task as a symbol' do
      expect(maintenance.run(:rotate)).to eq('3')
      expect(Gitlab::Database::PgAsh).to have_received(:execute).with(conn, 'SELECT ash.rotate() AS result')
    end

    it 'refuses a task that is not a known ash function' do
      expect { maintenance.run('uninstall') }.to raise_error(described_class::UnknownTaskError)
      expect(Gitlab::Database::PgAsh).not_to have_received(:execute)
    end
  end
end
