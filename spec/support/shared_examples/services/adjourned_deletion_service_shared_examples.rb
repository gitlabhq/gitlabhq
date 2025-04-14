# frozen_string_literal: true

RSpec.shared_examples 'adjourned deletion service' do
  before do
    stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
  end

  shared_examples 'user can remove resource' do
    it 'enqueues the resource destroy worker' do
      expect(destroy_worker).to receive(perform_method).with(*destroy_worker_params)

      service.execute
    end

    it 'removes the resource' do
      service.execute

      record_exists = resource.class.exists?(resource.id)
      expect(record_exists).to be_falsey
    end
  end

  shared_examples 'user cannot remove' do
    it 'uses admin bot to restore the resource', :enable_admin_mode do
      service.execute

      expect(resource.reload.marked_for_deletion?).to be(false)
    end
  end

  context 'when user can remove resource', :sidekiq_inline do
    context 'when user is an owner' do
      let(:user) { create(:user) }

      before do
        resource.add_owner(user)
      end

      it_behaves_like 'user can remove resource'
    end

    context 'when user is an admin with admin mode enabled', :enable_admin_mode do
      let(:user) { create(:admin) }

      it_behaves_like 'user can remove resource'
    end

    context 'when user is an admin with admin mode disabled' do
      let(:user) { create(:admin) }

      before do
        stub_application_setting(admin_mode: false)
      end

      it_behaves_like 'user can remove resource'
    end
  end

  context 'when user cannot remove the resource', :sidekiq_inline do
    let(:user) { create(:user) }

    context 'when user is non-admin with admin mode enabled', :enable_admin_mode do
      before do
        resource.add_maintainer(user)
      end

      it_behaves_like 'user cannot remove'
    end

    context 'when user has maintainer access' do
      before do
        resource.add_maintainer(user)
      end

      it_behaves_like 'user cannot remove'
    end

    context 'when user is blocked' do
      before do
        user.block!
      end

      it_behaves_like 'user cannot remove'
    end

    context 'when user is banned' do
      before do
        user.ban!
      end

      it_behaves_like 'user cannot remove'
    end
  end
end
