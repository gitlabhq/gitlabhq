require 'spec_helper'

describe 'Gitlab::PushDataBuilder' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }


  describe :build_sample do
    let(:data) { Gitlab::PushDataBuilder.build_sample(project, user) }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:before]).to eq('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    it { expect(data[:after]).to eq('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    it { expect(data[:ref]).to eq('refs/heads/master') }
    it { expect(data[:commits].size).to eq(3) }
    it { expect(data[:repository][:git_http_url]).to eq(project.http_url_to_repo) }
    it { expect(data[:repository][:git_ssh_url]).to eq(project.ssh_url_to_repo) }
    it { expect(data[:repository][:visibility_level]).to eq(project.visibility_level) }
    it { expect(data[:total_commits_count]).to eq(3) }
    it { expect(data[:added]).to eq(["gitlab-grack"]) }
    it { expect(data[:modified]).to eq([".gitmodules", "files/ruby/popen.rb", "files/ruby/regex.rb"]) }
    it { expect(data[:removed]).to eq([]) }
  end

  describe :build do
    let(:data) do
      Gitlab::PushDataBuilder.build(project,
                                    user,
                                    Gitlab::Git::BLANK_SHA,
                                    '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b',
                                    'refs/tags/v1.1.0')
    end

    it { expect(data).to be_a(Hash) }
    it { expect(data[:before]).to eq(Gitlab::Git::BLANK_SHA) }
    it { expect(data[:checkout_sha]).to eq('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    it { expect(data[:after]).to eq('8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b') }
    it { expect(data[:ref]).to eq('refs/tags/v1.1.0') }
    it { expect(data[:commits]).to be_empty }
    it { expect(data[:total_commits_count]).to be_zero }
    it { expect(data[:added]).to eq([]) }
    it { expect(data[:modified]).to eq([]) }
    it { expect(data[:removed]).to eq([]) }
  end
end
