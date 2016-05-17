require 'spec_helper'

describe Gitlab::ImportUrl do

  let(:credentials) { { user: 'blah', password: 'password' } }
  let(:url) { "https://github.com/me/project.git" }
  let(:import_url) do
    described_class.new(url, credentials: credentials)
  end

  describe 'full_url' do
    it { expect(import_url.full_url).to eq("https://blah:password@github.com/me/project.git") }
  end

  describe 'sanitized_url' do
    it { expect(import_url.sanitized_url).to eq("https://github.com/me/project.git") }
  end

  describe 'credentials' do
    it { expect(import_url.credentials).to eq(credentials) }
  end

  context 'URL encoding' do
    describe 'not encoded URL' do
      let(:url) { "https://github.com/me/my project.git" }
      it { expect(import_url.sanitized_url).to eq("https://github.com/me/my%20project.git") }
    end

    describe 'already encoded URL' do
      let(:url) { "https://github.com/me/my%20project.git" }
      it { expect(import_url.sanitized_url).to eq("https://github.com/me/my%20project.git") }
    end
  end
end
