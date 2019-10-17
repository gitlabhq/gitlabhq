# frozen_string_literal: true

require 'spec_helper'

describe NewReleaseWorker do
  let(:release) { create(:release) }

  it 'sends a new release notification' do
    expect_any_instance_of(NotificationService).to receive(:send_new_release_notifications).with(release)

    described_class.new.perform(release.id)
  end
end
