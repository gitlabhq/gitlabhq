# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::CreateService, feature_category: :compliance_management do
  let(:name) { 'master' }
  let(:params) do
    {
      name: name,
      merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
      push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
    }
  end

  subject(:service) { described_class.new(entity, user, params) }

  shared_examples 'execute with entity' do
    describe '#execute' do
      it 'creates a new protected branch' do
        expect { service.execute }.to change(ProtectedBranch, :count).by(1)
        expect(entity.protected_branches.last.push_access_levels.map(&:access_level)).to match_array([Gitlab::Access::MAINTAINER])
        expect(entity.protected_branches.last.merge_access_levels.map(&:access_level)).to match_array([Gitlab::Access::MAINTAINER])
      end

      it 'publishes ProtectedBranchCreatedEvent event' do
        expect { service.execute }.to publish_event(Repositories::ProtectedBranchCreatedEvent)
          .with(
            protected_branch_id: an_instance_of(Integer),
            parent_id: entity.id,
            parent_type: entity.is_a?(Project) ? 'project' : 'group'
          )
      end

      it 'refreshes the cache' do
        expect_next_instance_of(ProtectedBranches::CacheService) do |cache_service|
          expect(cache_service).to receive(:refresh)
        end

        service.execute
      end

      context 'when protecting a branch with a name that contains HTML tags' do
        let(:name) { 'foo<b>bar<\b>' }

        it 'creates a new protected branch' do
          expect { service.execute }.to change(ProtectedBranch, :count).by(1)
          expect(entity.protected_branches.last.name).to eq(name)
        end
      end

      context 'when a policy restricts rule creation' do
        it "prevents creation of the protected branch rule" do
          disallow(:create_protected_branch, an_instance_of(ProtectedBranch))

          expect do
            service.execute
          end.to raise_error(Gitlab::Access::AccessDeniedError)
        end

        it 'creates a new protected branch if we skip authorization step' do
          expect { service.execute(skip_authorization: true) }.to change(ProtectedBranch, :count).by(1)
        end
      end
    end
  end

  context 'with entity project' do
    let_it_be_with_reload(:entity) { create(:project) }
    let(:user) { entity.first_owner }

    it_behaves_like 'execute with entity'

    it 'refreshes all_protected_branches' do
      expect(entity).to receive_message_chain(:all_protected_branches, :reset)

      service.execute
    end
  end

  context 'with entity group' do
    let_it_be_with_reload(:entity) { create(:group) }
    let_it_be_with_reload(:user) { create(:user) }

    before do
      allow(Ability).to receive(:allowed?).with(user, :create_protected_branch, instance_of(ProtectedBranch)).and_return(true)
    end

    it_behaves_like 'execute with entity'
  end

  def disallow(ability, protected_branch)
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, ability, protected_branch).and_return(false)
  end
end
