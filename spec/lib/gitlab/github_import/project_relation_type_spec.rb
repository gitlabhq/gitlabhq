# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ProjectRelationType, :manage, feature_category: :importers do
  subject(:project_relation_type) { described_class.new(client) }

  let(:octokit) { instance_double(Octokit::Client) }
  let(:client) do
    instance_double(Gitlab::GithubImport::Clients::Proxy, octokit: octokit, user: { login: 'nickname' })
  end

  describe '#for', :use_clean_rails_redis_caching do
    before do
      allow(client).to receive(:each_object).with(:organizations).and_yield({ login: 'great-org' })
      allow(octokit).to receive(:access_token).and_return('stub')
    end

    context "when it's user owned repo" do
      let(:import_source) { 'nickname/repo_name' }

      it { expect(project_relation_type.for(import_source)).to eq 'owned' }
    end

    context "when it's organization repo" do
      let(:import_source) { 'great-org/repo_name' }

      it { expect(project_relation_type.for(import_source)).to eq 'organization' }
    end

    context "when it's user collaborated repo" do
      let(:import_source) { 'some-another-namespace/repo_name' }

      it { expect(project_relation_type.for(import_source)).to eq 'collaborated' }
    end

    context 'with cache' do
      let(:import_source) { 'some-another-namespace/repo_name' }

      it 'calls client only once during 5 minutes timeframe', :request_store do
        expect(project_relation_type.for(import_source)).to eq 'collaborated'
        expect(project_relation_type.for('another/repo')).to eq 'collaborated'

        expect(client).to have_received(:each_object).once
        expect(client).to have_received(:user).once
      end
    end
  end
end
