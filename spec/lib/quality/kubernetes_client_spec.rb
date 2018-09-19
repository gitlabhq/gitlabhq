# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Quality::KubernetesClient do
  subject { described_class.new(namespace: 'review-apps-ee') }

  describe '#cleanup' do
    it 'calls kubectl with the correct arguments' do
      # popen_with_detail will receive an array with a bunch of arguments; we're
      # only concerned with it having the correct namespace and release name
      expect(Gitlab::Popen).to receive(:popen_with_detail) do |args|
        expect(args)
          .to satisfy_one { |arg| arg.start_with?('-n "review-apps-ee" get') }
        expect(args)
          .to satisfy_one { |arg| arg == 'grep "my-release"' }
        expect(args)
          .to satisfy_one { |arg| arg.end_with?('-n "review-apps-ee" delete') }
      end

      # We're not verifying the output here, just silencing it
      expect { subject.cleanup(release_name: 'my-release') }.to output.to_stdout
    end
  end
end
