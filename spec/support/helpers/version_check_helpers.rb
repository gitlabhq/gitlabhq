# frozen_string_literal: true

module VersionCheckHelpers
  def stub_version_check(response)
    allow(Rails.cache).to receive(:fetch).and_call_original
    allow(Rails.cache).to receive(:fetch).with('version_check').and_return(response)
  end
end
