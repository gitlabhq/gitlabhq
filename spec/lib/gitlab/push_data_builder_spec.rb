require 'spec_helper'

describe 'Gitlab::PushDataBuilder' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }


  describe :build_sample do
    let(:data) { Gitlab::PushDataBuilder.build_sample(project, user) }

    it { data.should be_a(Hash) }
    it { data[:before].should == '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
    it { data[:after].should == '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
    it { data[:ref].should == 'refs/heads/master' }
    it { data[:commits].size.should == 3 }
    it { data[:total_commits_count].should == 3 }
  end

  describe :build do
    let(:data) do
      Gitlab::PushDataBuilder.build(project,
                                    user,
                                    Gitlab::Git::BLANK_SHA,
                                    '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b',
                                    'refs/tags/v1.1.0')
    end

    it { data.should be_a(Hash) }
    it { data[:before].should == Gitlab::Git::BLANK_SHA }
    it { data[:checkout_sha].should == '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
    it { data[:after].should == '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b' }
    it { data[:ref].should == 'refs/tags/v1.1.0' }
    it { data[:commits].should be_empty }
    it { data[:total_commits_count].should be_zero }
  end
end
