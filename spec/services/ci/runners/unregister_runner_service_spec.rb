# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::UnregisterRunnerService, '#execute', feature_category: :runner do
  subject(:execute) { described_class.new(runner, 'some_token').execute }

  let(:runner) { create(:ci_runner) }

  it 'destroys runner' do
    expect(runner).to receive(:destroy).once.and_call_original

    expect do
      expect(execute).to be_success
    end.to change { Ci::Runner.count }.by(-1)
    expect(runner[:errors]).to be_nil
  end
end
