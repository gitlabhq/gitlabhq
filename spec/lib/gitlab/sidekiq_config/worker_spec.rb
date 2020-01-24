# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::SidekiqConfig::Worker do
  def create_worker(queue:, weight: 0)
    namespace = queue.include?(':') && queue.split(':').first
    inner_worker = double(queue: queue, queue_namespace: namespace, get_weight: weight)

    described_class.new(inner_worker, ee: false)
  end

  describe '#ee?' do
    it 'returns the EE status set on creation' do
      expect(described_class.new(double, ee: true)).to be_ee
      expect(described_class.new(double, ee: false)).not_to be_ee
    end
  end

  describe '#==' do
    def worker_with_yaml(yaml)
      described_class.new(double, ee: false).tap do |worker|
        allow(worker).to receive(:to_yaml).and_return(yaml)
      end
    end

    it 'defines two workers as equal if their YAML representations are equal' do
      expect(worker_with_yaml('a')).to eq(worker_with_yaml('a'))
      expect(worker_with_yaml('a')).not_to eq(worker_with_yaml('b'))
    end

    it 'returns true when a worker is compared with its YAML representation' do
      expect(worker_with_yaml('a')).to eq('a')
      expect(worker_with_yaml(a: 1, b: 2)).to eq(a: 1, b: 2)
    end
  end

  describe 'delegations' do
    [
      :feature_category_not_owned?, :get_feature_category, :get_weight,
      :get_worker_resource_boundary, :latency_sensitive_worker?, :queue,
      :queue_namespace, :worker_has_external_dependencies?
    ].each do |meth|
      it "delegates #{meth} to the worker class" do
        worker = double

        expect(worker).to receive(meth)

        described_class.new(worker, ee: false).send(meth)
      end
    end
  end

  describe 'sorting' do
    it 'sorts queues with a namespace before those without a namespace' do
      namespaced_worker = create_worker(queue: 'namespace:queue')
      plain_worker = create_worker(queue: 'a_queue')

      expect([plain_worker, namespaced_worker].sort)
        .to eq([namespaced_worker, plain_worker])
    end

    it 'sorts alphabetically by queue' do
      workers = [
        create_worker(queue: 'namespace:a'),
        create_worker(queue: 'namespace:b'),
        create_worker(queue: 'other_namespace:a'),
        create_worker(queue: 'other_namespace:b'),
        create_worker(queue: 'a'),
        create_worker(queue: 'b')
      ]

      expect(workers.shuffle.sort).to eq(workers)
    end
  end

  describe 'YAML encoding' do
    it 'encodes the worker in YAML as a string of the queue' do
      worker_a = create_worker(queue: 'a')
      worker_b = create_worker(queue: 'b')

      expect(YAML.dump(worker_a)).to eq(YAML.dump('a'))
      expect(YAML.dump([worker_a, worker_b]))
        .to eq(YAML.dump(%w[a b]))
    end
  end

  describe '#namespace_and_weight' do
    it 'returns a namespace, weight pair for the worker' do
      expect(create_worker(queue: 'namespace:a', weight: 2).namespace_and_weight)
        .to eq(['namespace', 2])
    end
  end

  describe '#queue_and_weight' do
    it 'returns a queue, weight pair for the worker' do
      expect(create_worker(queue: 'namespace:a', weight: 2).queue_and_weight)
        .to eq(['namespace:a', 2])
    end
  end
end
