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
    it { is_expected.to validate_presence_of(:project) }
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

    context 'with custom instance prefix' do
      let(:instance_prefix) { 'instanceprefix' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it 'sets an random token starting with instance prefix' do
        trigger = create(:ci_trigger_without_token, project: project)

        expect(trigger.token).not_to be_nil
        expect(trigger.token).to start_with(instance_prefix)
      end

      context 'with feature flag custom_prefix_for_all_token_types disabled' do
        before do
          stub_feature_flags(custom_prefix_for_all_token_types: false)
        end

        it 'starts with TRIGGER_TOKEN_PREFIX' do
          trigger = create(:ci_trigger_without_token, project: project)

          expect(trigger.token).to start_with(Ci::Trigger::TRIGGER_TOKEN_PREFIX)
        end
      end
    end
  end

  describe 'scopes' do
    describe '.with_last_used' do
      let_it_be(:ci_trigger) { create(:ci_trigger, project: create(:project)) }

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

    describe '.with_token' do
      context 'when ff lookup for encrypted token is enabled' do
        let_it_be(:project) { create(:project) }
        let_it_be(:trigger_1) { create(:ci_trigger, project: project) }
        let_it_be(:trigger_2) { create(:ci_trigger, project: project) }
        let_it_be(:trigger_3) { create(:ci_trigger, project: project) }

        it 'returns the trigger for a valid token' do
          result = described_class.with_token(trigger_1.token)

          expect(result).to contain_exactly(trigger_1)
        end

        it 'returns the triggers for multiple valid tokens' do
          result = described_class.with_token([trigger_1.token, trigger_2.token])

          expect(result).to contain_exactly(trigger_1, trigger_2)
        end

        it 'ignores blank tokens' do
          result = described_class.with_token([nil, '', '   '])

          expect(result).to be_empty
        end

        it 'does not return triggers for invalid token' do
          result = described_class.with_token('nonexistent-token')

          expect(result).to be_empty
        end
      end

      context 'when ff lookup for encrypted token is disabled' do
        let_it_be(:project) { create(:project) }
        let_it_be(:trigger_1) { create(:ci_trigger, project: project) }
        let_it_be(:trigger_2) { create(:ci_trigger, project: project) }
        let_it_be(:trigger_3) { create(:ci_trigger, project: project) }

        before do
          stub_feature_flags(encrypted_trigger_token_lookup: false)
        end

        it 'returns the trigger for a valid token' do
          result = described_class.with_token(trigger_1.token)

          expect(result).to contain_exactly(trigger_1)
        end

        it 'returns the triggers for multiple valid tokens' do
          result = described_class.with_token([trigger_1.token, trigger_2.token])

          expect(result).to contain_exactly(trigger_1, trigger_2)
        end

        it 'ignores blank tokens' do
          result = described_class.with_token([nil, '', '   '])

          expect(result).to be_empty
        end

        it 'does not return triggers for invalid token' do
          result = described_class.with_token('nonexistent-token')

          expect(result).to be_empty
        end
      end
    end
  end

  describe '.prefix_for_trigger_token' do
    subject(:prefix_for_trigger_token) { described_class.prefix_for_trigger_token }

    context 'without custom instance prefix' do
      it 'starts with TRIGGER_TOKEN_PREFIX' do
        expect(prefix_for_trigger_token).to start_with(described_class::TRIGGER_TOKEN_PREFIX)
      end
    end

    context 'with custom instance prefix' do
      let(:instance_prefix) { 'instanceprefix' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it 'returns instance prefix with TRIGGER_TOKEN_PREFIX' do
        expect(prefix_for_trigger_token).to start_with("#{instance_prefix}-#{described_class::TRIGGER_TOKEN_PREFIX}")
      end

      context 'with feature flag custom_prefix_for_all_token_types disabled' do
        before do
          stub_feature_flags(custom_prefix_for_all_token_types: false)
        end

        it 'starts with TRIGGER_TOKEN_PREFIX' do
          expect(prefix_for_trigger_token).to start_with(described_class::TRIGGER_TOKEN_PREFIX)
        end
      end
    end
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
    let(:trigger) { create(:ci_trigger, project: project) }

    subject { trigger.short_token }

    it 'returns shortened token without prefix' do
      is_expected.not_to eq(Ci::Trigger::TRIGGER_TOKEN_PREFIX[0..4])
    end

    context 'token does not have a prefix' do
      before do
        trigger.token = '12345678'
      end

      it 'returns shortened token' do
        is_expected.to eq('1234')
      end
    end

    context 'with custom instance prefix', :aggregate_failures do
      let(:instance_prefix) { 'instanceprefix' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it 'returns shortened token with neither custom, nor default prefix' do
        trigger = create(:ci_trigger_without_token, project: project)
        expect(trigger.token).to start_with(instance_prefix)
        expect(trigger.short_token).not_to eq(instance_prefix[0...4])
        expect(trigger.short_token).not_to eq(Ci::Trigger::TRIGGER_TOKEN_PREFIX[0...4])
      end

      context 'with feature flag custom_prefix_for_all_token_types disabled' do
        before do
          stub_feature_flags(custom_prefix_for_all_token_types: false)
        end

        it 'returns shortened token without prefix' do
          expect(trigger.token).to start_with(Ci::Trigger::TRIGGER_TOKEN_PREFIX)
          expect(trigger.short_token).not_to eq(Ci::Trigger::TRIGGER_TOKEN_PREFIX[0...4])
        end
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
    let(:factory_attributes) { { project: project } }
  end

  it_behaves_like 'loose foreign key with custom delete limit' do
    let(:from_table) { "p_ci_pipelines" }
    let(:delete_limit) { 50 }
  end

  context 'loose foreign key on ci_triggers.owner_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:user) }
      let!(:model) { create(:ci_trigger, owner: parent, project: project) }
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
        expect(trigger.token_encrypted).not_to be_nil
      end
    end

    context 'when token is provided' do
      it 'encrypts the given token' do
        trigger = create(:ci_trigger, project: project)

        expect(trigger.token).not_to be_nil
        expect(trigger.token_encrypted).not_to be_nil
      end
    end

    context 'when token is being updated' do
      it 'encrypts the given token' do
        trigger = create(:ci_trigger, project: project, token: "token")
        expect { trigger.update!(token: "new token") }
          .to change { trigger.token }.from("token").to("new token")
          .and change { trigger.token_encrypted }
      end
    end
  end
end
