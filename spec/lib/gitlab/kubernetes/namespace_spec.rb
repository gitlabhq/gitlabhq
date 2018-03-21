require 'spec_helper'

describe Gitlab::Kubernetes::Namespace do
  let(:name) { 'a_namespace' }
  let(:client) { double('kubernetes client') }
  subject { described_class.new(name, client) }

  it { expect(subject.name).to eq(name) }

  describe '#exists?' do
    context 'when namespace do not exits' do
      let(:exception) { ::Kubeclient::HttpError.new(404, "namespace #{name} not found", nil) }

      it 'returns false' do
        expect(client).to receive(:get_namespace).with(name).once.and_raise(exception)

        expect(subject.exists?).to be_falsey
      end
    end

    context 'when namespace exits' do
      let(:namespace) { ::Kubeclient::Resource.new(kind: 'Namespace', metadata: { name: name }) } # partial representation

      it 'returns true' do
        expect(client).to receive(:get_namespace).with(name).once.and_return(namespace)

        expect(subject.exists?).to be_truthy
      end
    end

    context 'when cluster cannot be reached' do
      let(:exception) { Errno::ECONNREFUSED.new }

      it 'raises exception' do
        expect(client).to receive(:get_namespace).with(name).once.and_raise(exception)

        expect { subject.exists? }.to raise_error(exception)
      end
    end
  end

  describe '#create!' do
    it 'creates a namespace' do
      matcher = have_attributes(metadata: have_attributes(name: name))
      expect(client).to receive(:create_namespace).with(matcher).once

      expect { subject.create! }.not_to raise_error
    end
  end

  describe '#ensure_exists!' do
    it 'checks for existing namespace before creating' do
      expect(subject).to receive(:exists?).once.ordered.and_return(false)
      expect(subject).to receive(:create!).once.ordered

      subject.ensure_exists!
    end

    it 'do not re-create an existing namespace' do
      expect(subject).to receive(:exists?).once.and_return(true)
      expect(subject).not_to receive(:create!)

      subject.ensure_exists!
    end
  end
end
