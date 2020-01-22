# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::SidekiqConfig::Worker do
  def worker_with_queue(queue)
    described_class.new(double(queue: queue), ee: false)
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
      :feature_category_not_owned?, :get_feature_category,
      :get_worker_resource_boundary, :latency_sensitive_worker?, :queue,
      :worker_has_external_dependencies?
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
      namespaced_worker = worker_with_queue('namespace:queue')
      plain_worker = worker_with_queue('a_queue')

      expect([plain_worker, namespaced_worker].sort)
        .to eq([namespaced_worker, plain_worker])
    end

    it 'sorts alphabetically by queue' do
      workers = [
        worker_with_queue('namespace:a'),
        worker_with_queue('namespace:b'),
        worker_with_queue('other_namespace:a'),
        worker_with_queue('other_namespace:b'),
        worker_with_queue('a'),
        worker_with_queue('b')
      ]

      expect(workers.shuffle.sort).to eq(workers)
    end
  end

  describe 'YAML encoding' do
    it 'encodes the worker in YAML as a string of the queue' do
      worker_a = worker_with_queue('a')
      worker_b = worker_with_queue('b')

      expect(YAML.dump(worker_a)).to eq(YAML.dump('a'))
      expect(YAML.dump([worker_a, worker_b]))
        .to eq(YAML.dump(%w[a b]))
    end
  end
end
