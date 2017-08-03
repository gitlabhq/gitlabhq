require 'rails_helper'

describe Gitlab::SidekiqConfig do
  describe '.queues' do
    let(:queues_file_path) { Rails.root.join('config', 'sidekiq_queues.yml') }

    context 'without except argument' do
      it 'returns all queues defined on config/sidekiq_queues.yml file' do
        expected_queues = YAML.load_file(queues_file_path)[:queues].map { |queue, _| queue }

        expect(described_class.queues).to eq(expected_queues)
      end
    end

    context 'with except argument' do
      it 'returns queues on config/sidekiq_queues.yml filtering out excluded ones' do
        expected_queues =
          YAML.load_file(queues_file_path)[:queues].map { |queue, _| queue } - ['webhook']

        expect(described_class.queues(except: ['webhook'])).to eq(expected_queues)
      end
    end
  end
end
