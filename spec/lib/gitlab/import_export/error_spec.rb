# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Error do
  describe '.permission_error' do
    subject(:error) do
      described_class.permission_error(user, importable)
    end

    let(:user) { build(:user, id: 1) }

    context 'when supplied a project' do
      let(:importable) { build(:project, id: 1, name: 'project1') }

      it 'returns an error with the correct message' do
        expect(error.message)
          .to eq 'User with ID: 1 does not have required permissions for Project: project1 with ID: 1'
      end
    end

    context 'when supplied a group' do
      let(:importable) { build(:group, id: 1, name: 'group1') }

      it 'returns an error with the correct message' do
        expect(error.message)
          .to eq 'User with ID: 1 does not have required permissions for Group: group1 with ID: 1'
      end
    end
  end
end
