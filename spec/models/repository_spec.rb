require 'spec_helper'

describe Repository do
  include RepoHelpers

  let(:repository) { create(:project).repository }

  describe :branch_names_contains do
    subject { repository.branch_names_contains(sample_commit.id) }

    it { is_expected.to include('master') }
    it { is_expected.not_to include('feature') }
    it { is_expected.not_to include('fix') }
  end

  describe :last_commit_for_path do
    subject { repository.last_commit_for_path(sample_commit.id, '.gitignore').id }

    it { is_expected.to eq('c1acaa58bbcbc3eafe538cb8274ba387047b69f8') }
  end

  context :timestamps_by_user_log do
    before do
      Date.stub(:today).and_return(Date.new(2015, 03, 01))
    end

    describe 'single e-mail for user' do
      let(:user) { create(:user, email: sample_commit.author_email) }

      subject { repository.timestamps_by_user_log(user) }

      it { is_expected.to eq(['2014-08-06', '2014-07-31', '2014-07-31']) }
    end

    describe 'multiple emails for user' do
      let(:email_alias) { create(:email, email: another_sample_commit.author_email) }
      let(:user) { create(:user, email: sample_commit.author_email, emails: [email_alias]) }

      subject { repository.timestamps_by_user_log(user) }

      it { is_expected.to eq(['2015-01-10', '2014-08-06', '2014-07-31', '2014-07-31']) }
    end
  end

  context :commits_by_user_on_date_log do

    describe 'single e-mail for user' do
      let(:user) { create(:user, email: sample_commit.author_email) }
      let(:commit1) { '0ed8c6c6752e8c6ea63e7b92a517bf5ac1209c80' }
      let(:commit2) { '7d3b0f7cff5f37573aea97cebfd5692ea1689924' }

      subject { repository.commits_by_user_on_date_log(user,Date.new(2014, 07, 31)) }

      it 'contains the exepected commits' do
        expect(subject.flatten.map(&:id)).to eq([commit1, commit2])
      end
    end
  end
end
