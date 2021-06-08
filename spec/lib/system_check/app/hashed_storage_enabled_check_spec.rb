# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::App::HashedStorageEnabledCheck, :silence_stdout do
  describe '#check?' do
    it 'fails when hashed storage is disabled' do
      stub_application_setting(hashed_storage_enabled: false)

      expect(subject.check?).to be_falsey
    end

    it 'succeeds when hashed storage is enabled' do
      stub_application_setting(hashed_storage_enabled: true)

      expect(subject.check?).to be_truthy
    end
  end
end
