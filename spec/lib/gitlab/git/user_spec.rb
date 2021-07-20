# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::User do
  let(:username) { 'janedoe' }
  let(:name) { 'Jane Doé' }
  let(:email) { 'janedoé@example.com' }
  let(:gl_id) { 'user-123' }
  let(:timezone) { 'Asia/Shanghai' }
  let(:user) do
    described_class.new(username, name, email, gl_id, timezone)
  end

  subject { described_class.new(username, name, email, gl_id, timezone) }

  describe '.from_gitaly' do
    let(:gitaly_user) do
      Gitaly::User.new(gl_username: username, name: name.b, email: email.b, gl_id: gl_id, timezone: timezone)
    end

    subject { described_class.from_gitaly(gitaly_user) }

    it { expect(subject).to eq(user) }
  end

  describe '.from_gitlab' do
    context 'when no commit_email has been set' do
      let(:user) { build(:user, email: 'alice@example.com', commit_email: nil, timezone: timezone) }

      subject { described_class.from_gitlab(user) }

      it { expect(subject).to eq(described_class.new(user.username, user.name, user.email, 'user-', timezone)) }
    end

    context 'when commit_email has been set' do
      let(:user) { build(:user, email: 'alice@example.com', commit_email: 'bob@example.com', timezone: timezone) }

      subject { described_class.from_gitlab(user) }

      it { expect(subject).to eq(described_class.new(user.username, user.name, user.commit_email, 'user-', timezone)) }
    end
  end

  describe '#==' do
    def eq_other(username, name, email, gl_id, timezone)
      eq(described_class.new(username, name, email, gl_id, timezone))
    end

    it { expect(subject).to eq_other(username, name, email, gl_id, timezone) }

    it { expect(subject).not_to eq_other(nil, nil, nil, nil, timezone) }
    it { expect(subject).not_to eq_other(username + 'x', name, email, gl_id, timezone) }
    it { expect(subject).not_to eq_other(username, name + 'x', email, gl_id, timezone) }
    it { expect(subject).not_to eq_other(username, name, email + 'x', gl_id, timezone) }
    it { expect(subject).not_to eq_other(username, name, email, gl_id + 'x', timezone) }
    it { expect(subject).not_to eq_other(username, name, email, gl_id, 'Etc/UTC') }

    context 'when add_timezone_to_web_operations is disabled' do
      before do
        stub_feature_flags(add_timezone_to_web_operations: false)
      end

      it 'ignores timezone arg and sets Etc/UTC by default' do
        expect(user.timezone).to eq('Etc/UTC')
      end
    end
  end

  describe '#to_gitaly' do
    subject { user.to_gitaly }

    it 'creates a Gitaly::User with the correct data' do
      expect(subject).to be_a(Gitaly::User)
      expect(subject.gl_username).to eq(username)

      expect(subject.name).to eq(name.b)
      expect(subject.name).to be_a_binary_string

      expect(subject.email).to eq(email.b)
      expect(subject.email).to be_a_binary_string

      expect(subject.gl_id).to eq(gl_id)
      expect(subject.timezone).to eq(timezone)
    end
  end
end
