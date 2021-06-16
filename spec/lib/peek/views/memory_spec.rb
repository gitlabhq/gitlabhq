# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::Memory, :request_store do
  subject! { described_class.new }

  before do
    stub_memory_instrumentation
  end

  context 'with process_action.action_controller notification' do
    it 'returns empty results when it has not yet fired' do
      expect(subject.results).to eq({})
    end

    it 'returns memory instrumentation data when it has fired' do
      publish_notification

      expect(subject.results[:calls]).to eq('2 MB')
      expect(subject.results[:details]).to all(have_key(:item_header))
      expect(subject.results[:details]).to all(have_key(:item_content))
      expect(subject.results[:summary]).to include('Objects allocated' => '200 k')
      expect(subject.results[:summary]).to include('Allocator calls' => '500')
      expect(subject.results[:summary]).to include('Large allocations' => '1 KB')
    end
  end

  def stub_memory_instrumentation
    start_memory = {
      total_malloc_bytes: 1,
      total_mallocs: 2,
      total_allocated_objects: 3
    }
    allow(Gitlab::Memory::Instrumentation).to receive(:start_thread_memory_allocations).and_return(start_memory)
    allow(Gitlab::Memory::Instrumentation).to receive(:measure_thread_memory_allocations).with(start_memory).and_return({
      mem_total_bytes: 2_097_152,
      mem_bytes: 1024,
      mem_mallocs: 500,
      mem_objects: 200_000
    })
    Gitlab::InstrumentationHelper.init_instrumentation_data
  end

  def publish_notification
    headers = double
    allow(headers).to receive(:env).and_return('action_dispatch.request_id': 'req-42')

    ActiveSupport::Notifications.publish(
      'process_action.action_controller', Time.current - 1.second, Time.current, 'id', headers: headers
    )
  end
end
