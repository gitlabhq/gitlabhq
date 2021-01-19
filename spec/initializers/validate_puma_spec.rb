# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validate puma' do
  subject do
    load Rails.root.join('config/initializers/validate_puma.rb')
  end

  before do
    stub_env('PUMA_SKIP_CLUSTER_VALIDATION', skip_validation)
    stub_const('Puma', double)
    allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
    allow(Puma).to receive_message_chain(:cli_config, :options).and_return(workers: workers)
  end

  context 'for .com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    context 'when worker count is 0' do
      let(:workers) { 0 }

      context 'and PUMA_SKIP_CLUSTER_VALIDATION is true' do
        let(:skip_validation) { true }

        specify { expect { subject }.to raise_error(String) }
      end

      context 'and PUMA_SKIP_CLUSTER_VALIDATION is false' do
        let(:skip_validation) { false }

        specify { expect { subject }.to raise_error(String) }
      end
    end

    context 'when worker count is > 0' do
      let(:workers) { 2 }

      context 'and PUMA_SKIP_CLUSTER_VALIDATION is true' do
        let(:skip_validation) { true }

        specify { expect { subject }.not_to raise_error }
      end

      context 'and PUMA_SKIP_CLUSTER_VALIDATION is false' do
        let(:skip_validation) { false }

        specify { expect { subject }.not_to raise_error }
      end
    end
  end

  context 'for other environments' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
    end

    context 'when worker count is 0' do
      let(:workers) { 0 }

      context 'and PUMA_SKIP_CLUSTER_VALIDATION is true' do
        let(:skip_validation) { true }

        specify { expect { subject }.not_to raise_error }
      end

      context 'and PUMA_SKIP_CLUSTER_VALIDATION is false' do
        let(:skip_validation) { false }

        specify { expect { subject }.to raise_error(String) }
      end
    end

    context 'when worker count is > 0' do
      let(:workers) { 2 }

      context 'and PUMA_SKIP_CLUSTER_VALIDATION is true' do
        let(:skip_validation) { true }

        specify { expect { subject }.not_to raise_error }
      end

      context 'and PUMA_SKIP_CLUSTER_VALIDATION is false' do
        let(:skip_validation) { false }

        specify { expect { subject }.not_to raise_error }
      end
    end
  end
end
