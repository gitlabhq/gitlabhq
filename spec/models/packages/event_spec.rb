# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Event, feature_category: :package_registry do
  let(:event_type) { :push_package }
  let(:event_scope) { :npm }
  let(:originator_type) { :deploy_token }

  shared_examples 'handle forbidden event type' do |result: []|
    let(:event_type) { :search }

    it { is_expected.to eq(result) }
  end

  describe '.event_allowed?' do
    subject { described_class.event_allowed?(event_type) }

    it { is_expected.to eq(true) }

    it_behaves_like 'handle forbidden event type', result: false
  end

  describe '.unique_counters_for' do
    subject { described_class.unique_counters_for(event_scope, event_type, originator_type) }

    it { is_expected.to contain_exactly('i_package_npm_deploy_token') }

    it_behaves_like 'handle forbidden event type'

    context 'when an originator type is quest' do
      let(:originator_type) { :guest }

      it { is_expected.to eq([]) }
    end
  end
end
