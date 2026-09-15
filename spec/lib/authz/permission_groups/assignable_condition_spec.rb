# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::PermissionGroups::AssignableCondition, feature_category: :permissions do
  describe '.satisfied?' do
    let(:user) { build(:user) }

    it 'returns true when there are no conditions' do
      expect(described_class.satisfied?([], user)).to be(true)
    end

    it 'returns true when there are no conditions and no user' do
      expect(described_class.satisfied?([], nil)).to be(true)
    end

    it 'returns false when there are conditions but no user' do
      expect(described_class.satisfied?([:admin], nil)).to be(false)
    end

    it 'raises for an unknown condition' do
      expect { described_class.satisfied?([:unknown], user) }.to raise_error(KeyError)
    end

    it 'accepts string conditions' do
      expect(described_class.satisfied?(['admin'], user)).to be(false)
    end

    describe 'admin condition' do
      context 'when the user is an admin' do
        let(:user) { build(:admin) }

        it 'is satisfied' do
          expect(described_class.satisfied?([:admin], user)).to be(true)
        end
      end

      context 'when the user is not an admin' do
        it 'is not satisfied' do
          expect(described_class.satisfied?([:admin], user)).to be(false)
        end
      end
    end

    describe 'gitlab_team_member condition' do
      context 'when the user does not respond to gitlab_team_member?' do
        before do
          allow(user).to receive(:respond_to?).and_call_original
          allow(user).to receive(:respond_to?).with(:gitlab_team_member?).and_return(false)
        end

        it 'is not satisfied' do
          expect(described_class.satisfied?([:gitlab_team_member], user)).to be(false)
        end
      end
    end

    describe 'saas condition' do
      context 'when running on GitLab.com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'is satisfied' do
          expect(described_class.satisfied?([:saas], user)).to be(true)
        end
      end

      context 'when running on a self-managed instance' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it 'is not satisfied' do
          expect(described_class.satisfied?([:saas], user)).to be(false)
        end
      end
    end

    describe 'self_managed condition' do
      context 'when running on a self-managed instance' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        it 'is satisfied' do
          expect(described_class.satisfied?([:self_managed], user)).to be(true)
        end
      end

      context 'when running on GitLab.com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'is not satisfied' do
          expect(described_class.satisfied?([:self_managed], user)).to be(false)
        end
      end
    end

    describe 'multiple conditions' do
      context 'when one condition is not met' do
        let(:user) { build(:admin) }

        before do
          allow(user).to receive(:respond_to?).and_call_original
          allow(user).to receive(:respond_to?).with(:gitlab_team_member?).and_return(false)
        end

        it 'is not satisfied' do
          expect(described_class.satisfied?([:admin, :gitlab_team_member], user)).to be(false)
        end
      end
    end
  end

  describe 'EVALUATORS' do
    it 'covers every condition allowed by the JSON schema' do
      schema_path = Rails.root.join(
        ::Authz::PermissionGroups::Assignable::BASE_PATH, 'type_schema.json'
      )
      schema = Gitlab::Json::SafeParser.parse(File.read(schema_path))
      schema_conditions = schema.dig('properties', 'assignable_when', 'items', 'properties', 'condition', 'enum')

      expect(described_class::EVALUATORS.keys.map(&:to_s)).to match_array(schema_conditions)
    end
  end
end
