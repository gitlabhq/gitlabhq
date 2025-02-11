# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting a tree in a project', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:current_user) { project.first_owner }
  let(:path) { "" }
  let(:ref) { "master" }
  let(:fields) do
    <<~QUERY
      tree(path:"#{path}", ref:"#{ref}") {
        #{all_graphql_fields_for('tree'.classify)}
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('repository', {}, fields)
    )
  end

  context 'when path does not exist' do
    let(:path) { "testing123" }

    it 'returns empty tree' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']['trees']['edges']).to eq([])
      expect(graphql_data['project']['repository']['tree']['submodules']['edges']).to eq([])
      expect(graphql_data['project']['repository']['tree']['blobs']['edges']).to eq([])
    end

    it 'returns null commit' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['last_commit']).to be_nil
    end
  end

  context 'when ref does not exist' do
    let(:ref) { "testing123" }

    it 'returns empty tree' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']['trees']['edges']).to eq([])
      expect(graphql_data['project']['repository']['tree']['submodules']['edges']).to eq([])
      expect(graphql_data['project']['repository']['tree']['blobs']['edges']).to eq([])
    end

    it 'returns null commit' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['last_commit']).to be_nil
    end
  end

  context 'when ref and path exist' do
    it 'returns tree' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']).to be_present
    end

    it 'returns blobs, subtrees and submodules inside tree' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']['trees']['edges'].size).to be > 0
      expect(graphql_data['project']['repository']['tree']['blobs']['edges'].size).to be > 0
      expect(graphql_data['project']['repository']['tree']['submodules']['edges'].size).to be > 0
    end

    it 'returns tree latest commit' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']['repository']['tree']['lastCommit']).to be_present
    end
  end

  context 'when the ref points to a gpg-signed commit with a user' do
    let_it_be(:name) { GpgHelpers::User1.names.first }
    let_it_be(:email) { GpgHelpers::User1.emails.first }
    let_it_be(:current_user) { create(:user, name: name, email: email, owner_of: project) }
    let_it_be(:gpg_key) { create(:gpg_key, user: current_user, key: GpgHelpers::User1.public_key) }

    let(:ref) { GpgHelpers::SIGNED_AND_AUTHORED_SHA }
    let(:fields) do
      <<~QUERY
        tree(path:"#{path}", ref:"#{ref}") {
          lastCommit {
            signature {
              ... on GpgSignature {
                #{all_graphql_fields_for('GpgSignature'.classify, max_depth: 2)}
              }
            }
          }
        }
      QUERY
    end

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'returns the expected signature data' do
      signature = graphql_data['project']['repository']['tree']['lastCommit']['signature']
      expect(signature['commitSha']).to eq(ref)
      expect(signature['user']['id']).to eq("gid://gitlab/User/#{current_user.id}")
      expect(signature['gpgKeyUserName']).to eq(name)
      expect(signature['gpgKeyUserEmail']).to eq(email)
      expect(signature['verificationStatus']).to eq('VERIFIED')
      expect(signature['project']['id']).to eq("gid://gitlab/Project/#{project.id}")
    end
  end

  context 'when the ref points to a X.509-signed commit' do
    let_it_be(:email) { X509Helpers::User1.certificate_email }
    let_it_be(:current_user) { create(:user, email: email, owner_of: project) }

    let(:ref) { X509Helpers::User1.commit }
    let(:fields) do
      <<~QUERY
        tree(path:"#{path}", ref:"#{ref}") {
          lastCommit {
            signature {
              ... on X509Signature {
                #{all_graphql_fields_for('X509Signature'.classify, max_depth: 2)}
              }
            }
          }
        }
      QUERY
    end

    before do
      store = OpenSSL::X509::Store.new
      store.add_cert(OpenSSL::X509::Certificate.new(X509Helpers::User1.trust_cert))
      allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
      post_graphql(query, current_user: current_user)
    end

    it 'returns the expected signature data' do
      signature = graphql_data['project']['repository']['tree']['lastCommit']['signature']
      expect(signature['commitSha']).to eq(ref)
      expect(signature['verificationStatus']).to eq('VERIFIED')
      expect(signature['project']['id']).to eq("gid://gitlab/Project/#{project.id}")
    end

    it 'returns expected certificate data' do
      signature = graphql_data['project']['repository']['tree']['lastCommit']['signature']
      certificate = signature['x509Certificate']
      expect(certificate['certificateStatus']).to eq('good')
      expect(certificate['email']).to eq(X509Helpers::User1.certificate_email)
      expect(certificate['id']).to be_present
      expect(certificate['serialNumber']).to eq(X509Helpers::User1.certificate_serial.to_s)
      expect(certificate['subject']).to eq(X509Helpers::User1.certificate_subject)
      expect(certificate['subjectKeyIdentifier']).to eq(X509Helpers::User1.certificate_subject_key_identifier)
      expect(certificate['createdAt']).to be_present
      expect(certificate['updatedAt']).to be_present
    end
  end

  context 'when the ref points to a SSH-signed commit' do
    let_it_be(:project) { create(:project, :repository, :in_group) }

    let_it_be(:ref) { 'ssh-signed-commit' }
    let_it_be(:commit) { project.commit(ref) }
    let_it_be(:current_user) { create(:user, email: commit.committer_email, owner_of: project) }

    let(:fields) do
      <<~QUERY
        tree(path:"#{path}", ref:"#{ref}") {
          lastCommit {
            signature {
              ... on SshSignature {
                #{all_graphql_fields_for('SshSignature'.classify, max_depth: 2)}
              }
            }
          }
        }
      QUERY
    end

    let_it_be(:key) do
      create(:key, user: current_user, key: extract_public_key_from_commit(commit), expires_at: 2.days.from_now)
    end

    def extract_public_key_from_commit(commit)
      ssh_commit = Gitlab::Ssh::Commit.new(commit)
      signature_data = ::SSHData::Signature.parse_pem(ssh_commit.signature_text)
      signature_data.public_key.openssh
    end

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'returns the expected signature data' do
      signature = graphql_data['project']['repository']['tree']['lastCommit']['signature']

      expect(signature['commitSha']).to eq(commit.id)
      expect(signature['verificationStatus']).to eq('VERIFIED')
      expect(signature['project']['id']).to eq("gid://gitlab/Project/#{project.id}")
      expect(signature['user']['id']).to eq("gid://gitlab/User/#{current_user.id}")
      expect(signature['key']['id']).to eq("gid://gitlab/Key/#{key.id}")
      expect(signature['key']['title']).to eq(key.title)
      expect(signature['key']['createdAt']).to be_present
      expect(signature['key']['expiresAt']).to be_present
      expect(signature['key']['key']).to match(key.key)
    end
  end

  context 'when current user is nil' do
    it 'returns empty project' do
      post_graphql(query, current_user: nil)

      expect(graphql_data['project']).to be_nil
    end
  end
end
