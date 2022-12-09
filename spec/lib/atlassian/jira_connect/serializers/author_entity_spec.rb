# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::AuthorEntity, feature_category: :integrations do
  subject { described_class.represent(user).as_json }

  context 'when object is a User model' do
    let(:user) { build_stubbed(:user) }

    it 'exposes all fields' do
      expect(subject.keys).to contain_exactly(:name, :email, :username, :url, :avatar)
    end
  end

  context 'when object is a CommitAuthor struct from a commit' do
    let(:user) { Atlassian::JiraConnect::Serializers::CommitEntity::CommitAuthor.new('Full Name', 'user@example.com') }

    it 'exposes name and email only' do
      expect(subject.keys).to contain_exactly(:name, :email)
    end
  end
end
