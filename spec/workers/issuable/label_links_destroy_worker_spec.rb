# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::LabelLinksDestroyWorker, feature_category: :team_planning do
  let(:job_args) { [1, 'MergeRequest'] }
  let(:service) { double }

  include_examples 'an idempotent worker' do
    it 'calls the Issuable::DestroyLabelLinksService' do
      expect(::Issuable::DestroyLabelLinksService).to receive(:new).twice.and_return(service)
      expect(service).to receive(:execute).twice

      subject
    end
  end
end
