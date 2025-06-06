# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Trigger, feature_category: :continuous_integration do
  let(:project) { create :project }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:owner) }
    it { is_expected.to have_many(:pipelines) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:owner) }
  end

  describe 'before_validation' do
    it 'sets an random token if none provided' do
      trigger = create(:ci_trigger_without_token, project: project)

      expect(trigger.token).not_to be_nil
      expect(trigger.token).to start_with(Ci::Trigger::TRIGGER_TOKEN_PREFIX)
    end

    it 'does not set a random token if one provided' do
      trigger = create(:ci_trigger, project: project, token: 'token')

      expect(trigger.token).to eq('token')
    end
  end

  describe 'scopes' do
    describe '.with_last_used' do
      let_it_be(:ci_trigger) { create(:ci_trigger) }

      context 'when no pipelines' do
        it 'returns the trigger with last_used as nil' do
          expect(described_class.with_last_used).to contain_exactly(ci_trigger)

          first = described_class.with_last_used.first
          expect(first.attributes).to have_key('last_used')
          expect(first.attributes['last_used']).to be_nil
          expect(first.last_used).to be_nil
        end

        it 'only queries once' do
          expect do
            expect(described_class.with_last_used.first.last_used).to be_nil
          end.to match_query_count(1)
        end
      end

      context 'when there are pipelines', :freeze_time do
        let!(:ci_pipeline_1) { create(:ci_pipeline, trigger: ci_trigger, created_at: 2.days.ago) }
        let!(:ci_pipeline_2) { create(:ci_pipeline, trigger: ci_trigger, created_at: 1.day.ago) }

        it 'returns the trigger with non-empty last_used' do
          expect(described_class.with_last_used).to contain_exactly(ci_trigger)

          first = described_class.with_last_used.first
          expect(first.attributes).to have_key('last_used')
          expect(first.attributes['last_used']).to eq(ci_pipeline_2.created_at)
          expect(first.last_used).to eq(ci_pipeline_2.created_at)
        end

        it 'only queries once' do
          expect do
            expect(described_class.with_last_used.first.last_used).to eq(ci_pipeline_2.created_at)
          end.to match_query_count(1)
        end
      end
    end
  end

  it_behaves_like 'encrypted attribute', :encrypted_token_tmp, :db_key_base_32 do
    let(:record) { create(:ci_trigger_without_token) }
  end

  describe '#last_used' do
    let_it_be(:project) { create :project }
    let_it_be_with_refind(:trigger) { create(:ci_trigger, project: project) }

    subject { trigger.last_used }

    it { is_expected.to be_nil }

    context 'when there is one pipeline', :freeze_time do
      let_it_be(:pipeline1) { create(:ci_empty_pipeline, trigger: trigger, project: project, created_at: '2025-02-13') }
      let_it_be(:build1) { create(:ci_build, pipeline: pipeline1) }

      it { is_expected.to eq(pipeline1.created_at) }

      context 'when there are two pipelines' do
        let_it_be(:pipeline2) do
          create(:ci_empty_pipeline, trigger: trigger, project: project, created_at: '2025-02-11')
        end

        let_it_be(:build2) { create(:ci_build, pipeline: pipeline2) }

        it { is_expected.to eq(pipeline2.created_at) }
      end
    end
  end

  describe '#short_token' do
    let(:trigger) { create(:ci_trigger) }

    subject { trigger.short_token }

    it 'returns shortened token without prefix' do
      is_expected.not_to start_with(Ci::Trigger::TRIGGER_TOKEN_PREFIX)
    end

    context 'token does not have a prefix' do
      before do
        trigger.token = '12345678'
      end

      it 'returns shortened token' do
        is_expected.to eq('1234')
      end
    end
  end

  describe '#can_access_project?' do
    let(:owner) { create(:user) }
    let(:trigger) { create(:ci_trigger, owner: owner, project: project) }

    subject { trigger.can_access_project? }

    context 'and is member of the project' do
      before do
        project.add_developer(owner)
      end

      it { is_expected.to eq(true) }
    end

    context 'and is not member of the project' do
      it { is_expected.to eq(false) }
    end
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:ci_trigger, owner: project.first_owner, project: project) }
  end

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :ci_trigger }
  end

  it_behaves_like 'loose foreign key with custom delete limit' do
    let(:from_table) { "p_ci_pipelines" }
    let(:delete_limit) { 50 }
  end

  context 'loose foreign key on ci_triggers.owner_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:user) }
      let!(:model) { create(:ci_trigger, owner: parent) }
    end
  end

  context 'loose foreign key on ci_triggers.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_trigger, project: parent) }
    end
  end

  describe 'encrypted_token' do
    context 'when token is not provided' do
      it 'encrypts the generated token' do
        trigger = create(:ci_trigger_without_token, project: project)

        expect(trigger.token).not_to be_nil
        expect(trigger.encrypted_token).not_to be_nil
        expect(trigger.encrypted_token_iv).not_to be_nil

        expect(trigger.reload.encrypted_token_tmp).to eq(trigger.token)
      end
    end

    context 'when token is provided' do
      it 'encrypts the given token' do
        trigger = create(:ci_trigger, project: project)

        expect(trigger.token).not_to be_nil
        expect(trigger.encrypted_token).not_to be_nil
        expect(trigger.encrypted_token_iv).not_to be_nil

        expect(trigger.reload.encrypted_token_tmp).to eq(trigger.token)
      end
    end

    context 'when token is being updated' do
      it 'encrypts the given token' do
        trigger = create(:ci_trigger, project: project, token: "token")
        expect { trigger.update!(token: "new token") }
          .to change { trigger.encrypted_token }
          .and change { trigger.encrypted_token_iv }
          .and change { trigger.encrypted_token_tmp }.from("token").to("new token")
      end
    end
  end
end
