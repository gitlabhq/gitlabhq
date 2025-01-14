# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PostReceive, :clean_gitlab_redis_shared_state, feature_category: :source_code_management do
  let(:args) { %w[gl_repository identifier changes push_options] }
  let(:new_worker) { Repositories::PostReceiveWorker }
  let(:new_worker_instance) { new_worker.new }

  it 'forwards perform to Repositories::PostReceiveWorker' do
    allow(new_worker).to receive(:new).and_return(new_worker_instance)
    allow(new_worker_instance).to receive(:perform)
    described_class.new.perform(*args)
    expect(new_worker_instance).to have_received(:perform).with(*args)
  end
end
