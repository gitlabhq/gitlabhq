require 'spec_helper'

describe Gitlab::ImportUrl do

  let(:credentials) { { user: 'blah', password: 'password' } }
  let(:import_url) do
    Gitlab::ImportUrl.new("https://github.com/me/project.git", credentials: credentials)
  end

  describe :full_url do
    it { expect(import_url.full_url).to eq("https://blah:password@github.com/me/project.git") }
  end

  describe :sanitized_url do
    it { expect(import_url.sanitized_url).to eq("https://github.com/me/project.git") }
  end

  describe :credentials do
    it { expect(import_url.credentials).to eq(credentials) }
  end
end
