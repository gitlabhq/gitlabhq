require 'spec_helper'

describe 'Gitlab::ImportUrlExposer' do

  describe :expose do
    let(:credentials) do
      Gitlab::ImportUrlExposer.expose(import_url: "https://github.com/me/project.git", credentials: {user: 'blah', password: 'password'})
    end

    it { expect(credentials).to be_a(URI) }
    it { expect(credentials.to_s).to eq("https://blah:password@github.com/me/project.git") }
  end
end
