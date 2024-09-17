# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::ProjectMemberBuilder do
  let_it_be(:project) { create(:project, :internal, name: 'gitlab') }
  let_it_be(:user) { create(:user, name: 'John Doe', username: 'johndoe', email: 'john@example.com') }
  let_it_be(:project_member) { create(:project_member, :developer, user: user, project: project) }

  describe '#build' do
    let(:data) { described_class.new(project_member).build(event) }
    let(:event_name) { data[:event_name] }
    let(:attributes) do
      [
        :event_name, :created_at, :updated_at, :project_name, :project_path, :project_path_with_namespace, :project_id, :user_username, :user_name, :user_email, :user_id, :access_level, :project_visibility
      ]
    end

    context 'data' do
      shared_examples_for 'includes the required attributes' do
        it 'includes the required attributes' do
          expect(data).to include(*attributes)
          expect(data[:project_name]).to eq('gitlab')
          expect(data[:project_path]).to eq(project.path)
          expect(data[:project_path_with_namespace]).to eq(project.full_path)
          expect(data[:project_id]).to eq(project.id)
          expect(data[:user_username]).to eq('johndoe')
          expect(data[:user_name]).to eq('John Doe')
          expect(data[:user_id]).to eq(user.id)
          expect(data[:user_email]).to eq(_('[REDACTED]'))
          expect(data[:access_level]).to eq('Developer')
          expect(data[:project_visibility]).to eq('internal')
        end
      end

      context 'on create' do
        let(:event) { :create }

        it { expect(event_name).to eq('user_add_to_team') }

        it_behaves_like 'includes the required attributes'
      end

      context 'on update' do
        let(:event) { :update }

        it { expect(event_name).to eq('user_update_for_team') }

        it_behaves_like 'includes the required attributes'
      end

      context 'on destroy' do
        let(:event) { :destroy }

        it { expect(event_name).to eq('user_remove_from_team') }

        it_behaves_like 'includes the required attributes'
      end

      context 'on request' do
        let(:event) { :request }

        it { expect(event_name).to eq('user_access_request_to_project') }

        it_behaves_like 'includes the required attributes'
      end

      context 'on deny' do
        let(:event) { :revoke }

        it { expect(event_name).to eq('user_access_request_revoked_for_project') }

        it_behaves_like 'includes the required attributes'
      end
    end
  end
end
