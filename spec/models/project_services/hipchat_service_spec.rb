# frozen_string_literal: true

require 'spec_helper'

# HipchatService is partially removed and it will be remove completely
# after the deletion of all the database records.
# https://gitlab.com/gitlab-org/gitlab/-/issues/27954
RSpec.describe HipchatService do
  let_it_be(:project) { create(:project) }

  subject(:service) { described_class.new(project: project) }

  it { is_expected.to be_valid }

  describe '#to_param' do
    subject { service.to_param }

    it { is_expected.to eq('hipchat') }
  end

  describe '#supported_events' do
    subject { service.supported_events }

    it { is_expected.to be_empty }
  end

  describe '#save' do
    it 'prevents records from being created or updated' do
      expect(service.save).to be_falsey

      expect(service.errors.full_messages).to include(
        'HipChat endpoint is deprecated and should not be created or modified.'
      )
    end
  end
end
