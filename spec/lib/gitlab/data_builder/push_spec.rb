require 'spec_helper'

describe Gitlab::DataBuilder::Push do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  describe '.build_sample' do
    let(:data) { described_class.build_sample(project, user) }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:before]).to eq('1b12f15a11fc6e62177bef08f47bc7b5ce50b141') }
    it { expect(data[:after]).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0') }
    it { expect(data[:ref]).to eq('refs/heads/master') }
    it { expect(data[:commits].size).to eq(3) }
    it { expect(data[:total_commits_count]).to eq(3) }
    it { expect(data[:commits].first[:added]).to eq(['bar/branch-test.txt']) }
    it { expect(data[:commits].first[:modified]).to eq([]) }
    it { expect(data[:commits].first[:removed]).to eq([]) }

    include_examples 'project hook data with deprecateds'
    include_examples 'deprecated repository hook data'
  end

  describe '.build' do
    let(:data) do
      described_class.build(project, user, Gitlab::Git::BLANK_SHA,
                            '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b',
                            'refs/tags/v1.1.0')
    end

    it { expect(data).to be_a(Hash) }
    it { expect(data[:before]).to eq(Gitlab::Git::BLANK_SHA) }
    it { expect(data[:checkout_sha]).to eq('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    it { expect(data[:after]).to eq('8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b') }
    it { expect(data[:ref]).to eq('refs/tags/v1.1.0') }
    it { expect(data[:user_id]).to eq(user.id) }
    it { expect(data[:user_name]).to eq(user.name) }
    it { expect(data[:user_username]).to eq(user.username) }
    it { expect(data[:user_email]).to eq(user.email) }
    it { expect(data[:user_avatar]).to eq(user.avatar_url) }
    it { expect(data[:project_id]).to eq(project.id) }
    it { expect(data[:project]).to be_a(Hash) }
    it { expect(data[:commits]).to be_empty }
    it { expect(data[:total_commits_count]).to be_zero }

    include_examples 'project hook data with deprecateds'
    include_examples 'deprecated repository hook data'

    it 'does not raise an error when given nil commits' do
      expect { described_class.build(spy, spy, spy, spy, 'refs/tags/v1.1.0', nil) }
        .not_to raise_error
    end
  end
end
