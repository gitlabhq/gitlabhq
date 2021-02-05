# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Pipeline::Context do
  let(:group) { instance_double(Group) }
  let(:user) { instance_double(User) }
  let(:bulk_import) { instance_double(BulkImport, user: user, configuration: :config) }

  let(:entity) do
    instance_double(
      BulkImports::Entity,
      bulk_import: bulk_import,
      group: group
    )
  end

  subject { described_class.new(entity) }

  describe '#group' do
    it { expect(subject.group).to eq(group) }
  end

  describe '#current_user' do
    it { expect(subject.current_user).to eq(user) }
  end

  describe '#current_user' do
    it { expect(subject.configuration).to eq(bulk_import.configuration) }
  end
end
