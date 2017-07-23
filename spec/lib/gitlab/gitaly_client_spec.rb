require 'spec_helper'

# We stub Gitaly in `spec/support/gitaly.rb` for other tests. We don't want
# those stubs while testing the GitalyClient itself.
describe Gitlab::GitalyClient, lib: true, skip_gitaly_mock: true do
  describe '.stub' do
    # Notice that this is referring to gRPC "stubs", not rspec stubs
    before do
      described_class.clear_stubs!
    end

    context 'when passed a UNIX socket address' do
      it 'passes the address as-is to GRPC' do
        address = 'unix:/tmp/gitaly.sock'
        allow(Gitlab.config.repositories).to receive(:storages).and_return({
          'default' => { 'gitaly_address' => address }
        })

        expect(Gitaly::CommitService::Stub).to receive(:new).with(address, any_args)

        described_class.stub(:commit_service, 'default')
      end
    end

    context 'when passed a TCP address' do
      it 'strips tcp:// prefix before passing it to GRPC::Core::Channel initializer' do
        address = 'localhost:9876'
        prefixed_address = "tcp://#{address}"

        allow(Gitlab.config.repositories).to receive(:storages).and_return({
          'default' => { 'gitaly_address' => prefixed_address }
        })

        expect(Gitaly::CommitService::Stub).to receive(:new).with(address, any_args)

        described_class.stub(:commit_service, 'default')
      end
    end
  end

  describe 'feature_enabled?' do
    let(:feature_name) { 'my_feature' }
    let(:real_feature_name) { "gitaly_#{feature_name}" }

    context 'when Gitaly is disabled' do
      before do
        allow(described_class).to receive(:enabled?).and_return(false)
      end

      it 'returns false' do
        expect(described_class.feature_enabled?(feature_name)).to be(false)
      end
    end

    context 'when the feature status is DISABLED' do
      let(:feature_status) { Gitlab::GitalyClient::MigrationStatus::DISABLED }

      it 'returns false' do
        expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
      end
    end

    context 'when the feature_status is OPT_IN' do
      let(:feature_status) { Gitlab::GitalyClient::MigrationStatus::OPT_IN }

      context "when the feature flag hasn't been set" do
        it 'returns false' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
        end
      end

      context "when the feature flag is set to disable" do
        before do
          Feature.get(real_feature_name).disable
        end

        it 'returns false' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
        end
      end

      context "when the feature flag is set to enable" do
        before do
          Feature.get(real_feature_name).enable
        end

        it 'returns true' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(true)
        end
      end

      context "when the feature flag is set to a percentage of time" do
        before do
          Feature.get(real_feature_name).enable_percentage_of_time(70)
        end

        it 'bases the result on pseudo-random numbers' do
          expect(Random).to receive(:rand).and_return(0.3)
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(true)

          expect(Random).to receive(:rand).and_return(0.8)
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
        end
      end
    end

    context 'when the feature_status is OPT_OUT' do
      let(:feature_status) { Gitlab::GitalyClient::MigrationStatus::OPT_OUT }

      context "when the feature flag hasn't been set" do
        it 'returns true' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(true)
        end
      end

      context "when the feature flag is set to disable" do
        before do
          Feature.get(real_feature_name).disable
        end

        it 'returns false' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
        end
      end
    end
  end
end
