# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemHookPolicy, feature_category: :webhooks do
  let_it_be_with_refind(:organization) { create(:organization) }
  let_it_be_with_refind(:other_organization) { create(:organization) }
  let_it_be_with_refind(:hook) { create(:system_hook, organization: organization) }

  let(:legacy_abilities) { %i[read_web_hook admin_web_hook] }

  subject(:policy) { described_class.new(user, hook) }

  context 'when the user is not an admin and not a member of the hook organization' do
    let_it_be(:user) { create(:user) }

    it 'cannot read or administer the hook' do
      expect(policy).to be_disallowed(*legacy_abilities)
    end
  end

  context 'when the user is an admin' do
    let_it_be(:user) { create(:admin) }

    context 'with admin mode enabled', :enable_admin_mode do
      it 'can read and administer the hook' do
        expect(policy).to be_allowed(*legacy_abilities)
      end

      context 'when the hook belongs to an organization the admin is not a member of' do
        let(:hook) { create(:system_hook, organization: other_organization) }

        it 'can read and administer the hook through the organization policy' do
          expect(other_organization.owner_user_ids).not_to include(user.id)
          expect(policy).to be_allowed(*legacy_abilities)
        end
      end
    end

    context 'with admin mode disabled' do
      it 'cannot read or administer the hook' do
        expect(policy).to be_disallowed(*legacy_abilities)
      end

      context 'when the admin is also an owner of the hook organization' do
        before_all do
          create(:organization_owner, organization: organization, user: user)
        end

        it 'cannot read or administer the hook' do
          expect(policy).to be_disallowed(*legacy_abilities)
        end
      end
    end
  end

  context 'when the user is an owner of the hook organization' do
    let_it_be(:user) { create(:user) }

    before_all do
      create(:organization_owner, organization: organization, user: user)
    end

    it 'can read and administer the hook' do
      expect(policy).to be_allowed(*legacy_abilities)
    end
  end

  context 'when the user is an owner of a different organization' do
    let_it_be(:user) { create(:user) }

    before_all do
      create(:organization_owner, organization: other_organization, user: user)
    end

    it 'cannot read or administer the hook' do
      expect(policy).to be_disallowed(*legacy_abilities)
    end
  end

  context 'when the user is a regular user of the hook organization' do
    let_it_be(:user) { create(:user) }

    before_all do
      create(:organization_user, organization: organization, user: user)
    end

    it 'cannot read or administer the hook' do
      expect(policy).to be_disallowed(*legacy_abilities)
    end
  end

  context 'when the user is an anonymous user' do
    let(:user) { nil }

    it 'cannot read or administer the hook' do
      expect(policy).to be_disallowed(*legacy_abilities)
    end
  end

  context 'when the organization grants only some of the granular webhook abilities' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let(:hook) { build_stubbed(:system_hook) }

    before do
      abilities = granted
      stub_const('PartialGrantOrganizationPolicy', Class.new(::BasePolicy) { rule { default }.enable(*abilities) })

      # A fresh class per example, so the ClassForClassCache never holds a stale entry.
      organization_class = Class.new do
        def self.declarative_policy_class = 'PartialGrantOrganizationPolicy'
      end

      allow(hook).to receive(:organization).and_return(organization_class.new)
    end

    where(:granted, :can_read, :can_administer) do
      %i[read_webhook]                      | true  | false
      %i[update_webhook]                    | false | false
      %i[delete_webhook]                    | false | false
      %i[create_webhook test_webhook]       | false | false
      %i[update_webhook delete_webhook]     | false | true
      %i[read_webhook update_webhook delete_webhook] | true | true
    end

    with_them do
      it 'derives the legacy abilities only when every granular ability they cover is granted' do
        expect(policy.allowed?(:read_web_hook)).to eq(can_read)
        expect(policy.allowed?(:admin_web_hook)).to eq(can_administer)
      end
    end
  end

  context 'when the hook has no organization' do
    let_it_be(:user) { create(:user) }
    let(:hook) { build_stubbed(:system_hook, organization: nil) }

    before_all do
      create(:organization_owner, organization: organization, user: user)
    end

    it 'cannot read or administer the hook' do
      expect(policy).to be_disallowed(*legacy_abilities)
    end

    context 'when the user is an instance admin with admin mode enabled', :enable_admin_mode do
      let_it_be(:user) { create(:admin) }

      it 'cannot read or administer the hook' do
        expect(policy).to be_disallowed(*legacy_abilities)
      end
    end
  end
end
