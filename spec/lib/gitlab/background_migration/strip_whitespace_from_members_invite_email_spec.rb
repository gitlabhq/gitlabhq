# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::StripWhitespaceFromMembersInviteEmail, :aggregate_failures, feature_category: :groups_and_projects do
  let(:organizations_table) { table(:organizations) }
  let(:namespaces_table) { table(:namespaces) }
  let(:members_table) { table(:members) }

  let(:organization) { organizations_table.create!(name: 'Organization', path: 'organization') }

  let(:group) do
    namespaces_table.create!(
      name: 'Group',
      path: 'group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  # Rows that should be fixed: invalid only due to surrounding whitespace.
  let!(:leading_whitespace) { create_member(' foo@bar.com') }
  let!(:trailing_whitespace) { create_member('foo@bar.com ') }
  let!(:both_sides) { create_member("\tfoo@bar.com\n") }

  # Rows that must be left untouched.
  let!(:already_valid) { create_member('clean@bar.com') }
  let!(:invalid_after_strip) { create_member('  not an email  ') }
  let!(:nil_email) { create_member(nil) }
  let!(:internal_whitespace) { create_member('foo @bar.com') }

  subject(:migration) do
    described_class.new(
      start_id: members_table.minimum(:id),
      end_id: members_table.maximum(:id),
      batch_table: :members,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  def create_member(invite_email)
    members_table.create!(
      source_id: group.id,
      source_type: 'Namespace',
      type: 'GroupMember',
      access_level: 30,
      notification_level: 3,
      member_namespace_id: group.id,
      invite_email: invite_email
    )
  end

  it 'strips whitespace only from rows that become valid emails' do
    migration.perform

    expect(leading_whitespace.reload.invite_email).to eq('foo@bar.com')
    expect(trailing_whitespace.reload.invite_email).to eq('foo@bar.com')
    expect(both_sides.reload.invite_email).to eq('foo@bar.com')
  end

  it 'leaves other rows unchanged' do
    migration.perform

    expect(already_valid.reload.invite_email).to eq('clean@bar.com')
    expect(invalid_after_strip.reload.invite_email).to eq('  not an email  ')
    expect(nil_email.reload.invite_email).to be_nil
    expect(internal_whitespace.reload.invite_email).to eq('foo @bar.com')
  end

  it 'is idempotent' do
    migration.perform
    expect { migration.perform }.not_to change { members_table.order(:id).pluck(:invite_email) }
  end

  # The job intentionally freezes its own copy of the email validation rules (see the constant
  # comments) so its behavior stays stable across the GitLab versions it may run on. These
  # expectations assert the frozen copies are a faithful snapshot of the validator the model
  # actually uses (`DeviseEmailValidator`, via `Member#invite_email`). They fail if the copy was
  # mistyped, or if the validator later changes, so any divergence is surfaced rather than silent.
  describe 'email validation constants' do
    it 'match the model DeviseEmailValidator rules' do
      expect(described_class::EMAIL_REGEXP).to eq(DeviseEmailValidator::DEFAULT_OPTIONS[:regexp])
      expect(described_class::ENCODED_WORD_REGEXP).to eq(DeviseEmailValidator::DEFAULT_OPTIONS[:encoded_word_regexp])
    end
  end
end
