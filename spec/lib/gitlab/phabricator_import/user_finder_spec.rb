# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::PhabricatorImport::UserFinder, :clean_gitlab_redis_cache do
  let(:project) { create(:project, namespace: create(:group)) }

  subject(:finder) { described_class.new(project, ['first-phid', 'second-phid']) }

  before do
    project.namespace.add_developer(existing_user)
  end

  describe '#find' do
    let!(:existing_user) { create(:user, username: 'existing-user') }
    let(:cache) { Gitlab::PhabricatorImport::Cache::Map.new(project) }

    before do
      allow(finder).to receive(:object_map).and_return(cache)
    end

    context 'for a cached phid' do
      before do
        cache.set_gitlab_model(existing_user, 'first-phid')
      end

      it 'returns the existing user' do
        expect(finder.find('first-phid')).to eq(existing_user)
      end

      it 'does not perform a find using the API' do
        expect(finder).not_to receive(:find_user_for_phid)

        finder.find('first-phid')
      end

      it 'excludes the phid from the request if one needs to be made' do
        client = instance_double(Gitlab::PhabricatorImport::Conduit::User)
        allow(finder).to receive(:client).and_return(client)

        expect(client).to receive(:users).with(['second-phid']).and_return([])

        finder.find('first-phid')
        finder.find('second-phid')
      end
    end

    context 'when the phid is not cached' do
      let(:response) do
        [
          instance_double(
            Gitlab::PhabricatorImport::Conduit::UsersResponse,
            users: [instance_double(Gitlab::PhabricatorImport::Representation::User, phabricator_id: 'second-phid', username: 'existing-user')]
          ),
          instance_double(
            Gitlab::PhabricatorImport::Conduit::UsersResponse,
            users: [instance_double(Gitlab::PhabricatorImport::Representation::User, phabricator_id: 'first-phid', username: 'other-user')]
          )
        ]
      end
      let(:client) do
        client = instance_double(Gitlab::PhabricatorImport::Conduit::User)
        allow(client).to receive(:users).and_return(response)

        client
      end

      before do
        allow(finder).to receive(:client).and_return(client)
      end

      it 'loads the users from the API once' do
        expect(client).to receive(:users).and_return(response).once

        expect(finder.find('second-phid')).to eq(existing_user)
        expect(finder.find('first-phid')).to be_nil
      end

      it 'adds found users to the cache' do
        expect { finder.find('second-phid') }
          .to change { cache.get_gitlab_model('second-phid') }
                .from(nil).to(existing_user)
      end

      it 'only returns users that are members of the project' do
        create(:user, username: 'other-user')

        expect(finder.find('first-phid')).to eq(nil)
      end
    end
  end
end
