# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::ImportUserCreator, feature_category: :importers do
  let(:group) { create(:group, organization: create(:organization)) }

  subject(:service) { described_class.new(portable: group) }

  it 'creates import user' do
    user = service.execute

    expect(user.user_type).to eq('import_user')
    expect(group.reload.import_user).to eq(user)
    expect(user.namespace.organization).to eq(group.organization)
  end

  context 'when import user already exists' do
    it 'returns existing import user' do
      user = create(:user)
      namespace_import_user = create(:namespace_import_user, import_user: user, namespace: group)

      import_user = service.execute

      expect(import_user.id).to eq(namespace_import_user.import_user.id)
    end
  end

  context 'when provided portable is a subgroup' do
    it 'creates import user on root group level' do
      subgroup = create(:group, parent: group)

      import_user = described_class.new(portable: subgroup).execute

      expect(import_user.reload.namespace_import_user.namespace).to eq(group)
    end
  end

  context 'when provided portable is a project' do
    it 'creates import user on root group level' do
      project = create(:project, group: group)

      import_user = described_class.new(portable: project).execute

      expect(group.reload.import_user).to eq(import_user)
    end
  end

  context 'when exception occurs' do
    it 'returns an error' do
      allow(service).to receive(:create_user).and_raise(ActiveRecord::RecordInvalid)

      expect { service.execute }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when portable is in user personal namespace' do
    it 'creates import user' do
      user_namespace = create(:user_namespace)
      user = create(:user, namespace: user_namespace)
      project = create(:project, creator: user, namespace: user_namespace)

      import_user = described_class.new(portable: project).execute

      expect(user.namespace.reload.import_user).to eq(import_user)
    end
  end

  context 'when namespace import user creation fails due to not unique error' do
    it 'logs and returns existing import user' do
      import_user = create(:user, :import_user)
      create(:namespace_import_user, import_user: import_user, namespace: group)

      allow(service).to receive(:import_user).and_return(nil, import_user)

      expect(::Import::Framework::Logger)
        .to receive(:warn)
        .with(
          message: 'Failed to create namespace_import_user',
          error: a_string_matching('PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint')
        )

      user = service.execute

      expect(user.id).to eq(import_user.id)
    end
  end
end
