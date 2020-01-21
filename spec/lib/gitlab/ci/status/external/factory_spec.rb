# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Status::External::Factory do
  let(:user) { create(:user) }
  let(:project) { resource.project }
  let(:status) { factory.fabricate! }
  let(:factory) { described_class.new(resource, user) }
  let(:external_url) { 'http://gitlab.com/status' }

  before do
    project.add_developer(user)
  end

  context 'when external status has a simple core status' do
    HasStatus::AVAILABLE_STATUSES.each do |simple_status|
      context "when core status is #{simple_status}" do
        let(:resource) do
          create(:generic_commit_status, status: simple_status,
                                         target_url: external_url)
        end

        let(:expected_status) do
          Gitlab::Ci::Status.const_get(simple_status.to_s.camelize, false)
        end

        it "fabricates a core status #{simple_status}" do
          expect(status).to be_a expected_status
        end

        it 'extends core status with common methods' do
          expect(status).to have_details
          expect(status).not_to have_action
          expect(status.details_path).to eq external_url
        end
      end
    end
  end
end
