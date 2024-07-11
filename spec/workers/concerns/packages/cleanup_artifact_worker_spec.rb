# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::CleanupArtifactWorker, feature_category: :package_registry do
  let_it_be(:worker_class) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      include ApplicationWorker
      include ::Packages::CleanupArtifactWorker
    end
  end

  let(:worker) { worker_class.new }

  describe '#model' do
    subject { worker.send(:model) }

    it { expect { subject }.to raise_error(NotImplementedError) }
  end

  describe '#log_metadata' do
    subject { worker.send(:log_metadata) }

    it { expect { subject }.to raise_error(NotImplementedError) }
  end

  describe '#log_cleanup_item' do
    subject { worker.send(:log_cleanup_item) }

    it { expect { subject }.to raise_error(NotImplementedError) }
  end
end
