# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Kubernetes::PodCmd do
  describe '.retry_command' do
    it 'constructs string properly' do
      command = 'my command'
      command_with_retries = "for i in $(seq 1 3); do #{command} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)"

      expect(described_class.retry_command(command)).to eq command_with_retries
    end
  end
end
