# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Glaz::PermissionCheck, feature_category: :permissions do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be_with_reload(:object) { create(:project) }

  subject(:check) { described_class.new(user, object, permission) }

  describe '#allowed? / #denied? / #reason' do
    # permit_role_granted policy:
    #   permit (principal, action, resource)
    #   when { context.user_permissions.contains(action) }
    #
    # The engine automatically injects the requested action into user_permissions,
    # so callers never need to pass it explicitly.
    describe 'permit_role_granted policy' do
      let(:permission) { "access_project" }

      it 'permits with permit_role_granted reason', :aggregate_failures do
        expect(check.allowed?).to be true
        expect(check.reason).to eq("permit_role_granted")
      end
    end

    describe 'forbid_archived_project policy' do
      context 'when permission is `write_project` on a non-archived project' do
        let(:permission) { "write_project" }

        it 'returns allowed with `permit_role_granted` reason', :aggregate_failures do
          expect(check.allowed?).to be true
          expect(check.denied?).to be false
          expect(check.reason).to eq("permit_role_granted")
        end
      end

      context 'when permission is `write_project` on an archived project' do
        let(:permission) { "write_project" }

        before do
          object.update!(archived: true)
        end

        it 'returns denied with `forbid_archived_project` reason', :aggregate_failures do
          expect(check.allowed?).to be false
          expect(check.denied?).to be true
          expect(check.reason).to eq("forbid_archived_project")
        end
      end

      context 'when permission is `access_project` on an archived project' do
        let(:permission) { "access_project" }

        before do
          object.update!(archived: true)
        end

        it 'returns allowed regardless of archived state', :aggregate_failures do
          expect(check.allowed?).to be true
          expect(check.reason).to eq("permit_role_granted")
        end
      end
    end
  end

  describe 'UUID stability' do
    let(:permission) { "write_project" }

    it 'produces the same result on repeated calls for the same inputs' do
      first_check  = check.allowed?
      second_check = check.allowed?

      expect(first_check).to eq(second_check)
    end
  end

  describe 'when the subject is not a User, Group, or Project' do
    let(:unsupported) { build_stubbed(:issue) }
    let(:permission) { "access_project" }

    subject(:check) { described_class.new(unsupported, object, permission) }

    it 'raises ArgumentError' do
      expect { check.allowed? }.to raise_error(ArgumentError, /no Glaz namespace id for Issue/)
    end
  end

  describe '#build_uuidv7' do
    let(:permission) { "access_project" }
    let(:uuidv7_format) { /\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/ }

    subject(:build_uuidv7) { check.send(:build_uuidv7, model) }

    context 'for a supported model' do
      let(:model) { user }

      it 'produces a valid UUIDv7' do
        expect(build_uuidv7).to match(uuidv7_format)
      end

      it 'is deterministic for the same model' do
        expect(build_uuidv7).to eq(check.send(:build_uuidv7, model))
      end

      it 'encodes the created_at timestamp in the time-ordered prefix' do
        ts_hex = format("%012x", (model.created_at.to_r * 1000).to_i)

        expect(build_uuidv7.delete('-')).to start_with(ts_hex)
      end
    end

    it 'does not collide across model types that share a namespace id and timestamp' do
      project = create(:project)
      other_user = create(:user, :with_namespace)
      allow(other_user).to receive_messages(namespace_id: project.project_namespace_id, created_at: project.created_at)

      expect(check.send(:build_uuidv7, other_user)).not_to eq(check.send(:build_uuidv7, project))
    end
  end
end
