# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderMemberships::CreateService, feature_category: :importers do
  describe '#execute', :aggregate_failures do
    let_it_be(:source_user) { create(:import_source_user) }
    let_it_be(:group) { nil }
    let_it_be(:project) { nil }

    let(:access_level) { Gitlab::Access::GUEST }
    let(:expires_at) { Date.today.next_month }
    let(:ignore_duplicate_errors) { false }

    subject(:result) do
      described_class.new(
        source_user: source_user,
        access_level: access_level,
        expires_at: expires_at,
        group: group,
        project: project,
        ignore_duplicate_errors: ignore_duplicate_errors
      ).execute
    end

    context 'when project is provided' do
      let_it_be(:project) { create(:project) }

      it 'saves the Import::Placeholders::Membership with the project' do
        expect { result }.to change { Import::Placeholders::Membership.count }.by(1)
        expect(result).to be_success
        expect(result[:reference]).to have_attributes(
          source_user: source_user,
          namespace: source_user.namespace,
          access_level: access_level,
          expires_at: expires_at,
          group: be_nil,
          project: project
        )
      end

      context 'when placeholder membership already exists' do
        let_it_be(:existing_membership) do
          create(:import_placeholder_membership, source_user: source_user, project: project)
        end

        context "when ignoring duplicate membership errors" do
          let(:ignore_duplicate_errors) { true }

          it 'does not create a member, logs information, and returns success' do
            expect_next_instance_of(::Import::Framework::Logger) do |logger|
              expect(logger).to receive(:info).with(
                message: 'Project or group has already been taken. Skipping placeholder membership creation',
                reference: be_a(Import::Placeholders::Membership)
              )
            end

            expect { result }.not_to change { Import::Placeholders::Membership.count }
            expect(result).to be_success
          end
        end

        context "when observing duplicate membership errors" do
          it 'returns an error' do
            expect { result }.not_to change { Import::Placeholders::Membership.count }
            expect(result).to be_error
            expect(result.http_status).to eq(:bad_request)
            expect(result.message).to include('Project has already been taken')
          end
        end
      end
    end

    context 'when group is provided' do
      let_it_be(:group) { create(:group) }

      it 'saves the Import::Placeholders::Membership with the group' do
        expect { result }.to change { Import::Placeholders::Membership.count }.by(1)
        expect(result).to be_success
        expect(result[:reference]).to have_attributes(
          source_user: source_user,
          namespace: source_user.namespace,
          access_level: access_level,
          expires_at: expires_at,
          group: group,
          project: be_nil
        )
      end
    end

    context 'when Import::Placeholders::Membership is invalid' do
      it 'returns an error' do
        expect { result }.not_to change { Import::Placeholders::Membership.count }
        expect(result).to be_error
        expect(result.http_status).to eq(:bad_request)
        expect(result.message).to include('one of group_id or project_id must be present')
      end
    end
  end
end
