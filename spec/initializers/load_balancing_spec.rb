# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'load_balancing', :delete, :reestablished_active_record_base do
  subject(:initialize_load_balancer) do
    load Rails.root.join('config/initializers/load_balancing.rb')
  end

  context 'for a clustered puma worker' do
    let!(:group) { create(:group, name: 'my group') }

    before do
      # Setup host-based load balancing
      # Patch in our load balancer config, simply pointing at the test database twice
      allow(Gitlab::Database::LoadBalancing::Configuration).to receive(:for_model) do |base_model|
        db_host = base_model.connection_pool.db_config.host

        Gitlab::Database::LoadBalancing::Configuration.new(base_model, [db_host, db_host])
      end

      # Pretend we are in clustered environment
      allow(Gitlab::Cluster::LifecycleEvents).to receive(:in_clustered_puma?).and_return(true)

      # Stub out middleware call, as not idempotent
      allow(Gitlab::Application.instance.middleware).to receive(:use)
    end

    after do
      # reset load balancing to original state
      allow(Gitlab::Database::LoadBalancing::Configuration).to receive(:for_model).and_call_original
      allow(Gitlab::Cluster::LifecycleEvents).to receive(:in_clustered_puma?).and_call_original

      load Rails.root.join('config/initializers/load_balancing.rb')
    end

    def simulate_puma_worker
      pid = Process.fork do
        # We call this in config/puma.rb
        Gitlab::Cluster::LifecycleEvents.do_worker_start

        yield
      end

      Process.waitpid(pid)
      expect($?).to be_success
    end

    it 'makes a query to a replica successfully' do
      # Clear any previous sticky writes
      ::Gitlab::Database::LoadBalancing::Session.clear_session

      initialize_load_balancer

      process_read, process_write = IO.pipe

      simulate_puma_worker do
        process_read.close

        group = Group.find_by_name('my group')
        process_write.write group.name
      end

      process_write.close
      expect(process_read.read).to eq(group.name)
    end

    it 'makes a query to the primary successfully' do
      initialize_load_balancer

      expect do
        simulate_puma_worker do
          Group.touch_all
        end

        group.reload
      end.to change(group, :updated_at)
    end
  end
end
