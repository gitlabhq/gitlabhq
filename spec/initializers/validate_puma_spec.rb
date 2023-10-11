# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validate puma' do
  subject do
    load Rails.root.join('config/initializers/validate_puma.rb')
  end

  before do
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

      specify { expect { subject }.to raise_error(String) }
    end

    context 'when worker count is > 0' do
      let(:workers) { 2 }

      specify { expect { subject }.not_to raise_error }
    end
  end

  context 'for other environments' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
    end

    context 'when worker count is 0' do
      let(:workers) { 0 }

      specify { expect { subject }.not_to raise_error }

      it 'warns about running Puma in a Single mode' do
        expect { subject }
          .to output(%r{https://gitlab.com/groups/gitlab-org/-/epics/5303})
          .to_stderr
      end
    end

    context 'when worker count is > 0' do
      let(:workers) { 2 }

      it 'does not issue a warning' do
        expect { subject }.not_to output.to_stderr
      end
    end
  end
end
