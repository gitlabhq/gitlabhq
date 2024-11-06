# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Topics::MergeService, :with_current_organization, feature_category: :shared do
  let_it_be(:namespace) { create(:namespace, organization: current_organization) }

  let_it_be(:source_topic) { create(:topic, name: 'source_topic', organization: current_organization) }
  let_it_be(:target_topic) { create(:topic, name: 'target_topic', organization: current_organization) }

  let_it_be(:project_1) { create(:project, :public, topic_list: source_topic.name, namespace: namespace) }
  let_it_be(:project_2) { create(:project, :private, topic_list: source_topic.name, namespace: namespace) }
  let_it_be(:project_3) { create(:project, :public, topic_list: target_topic.name, namespace: namespace) }

  let_it_be(:project_4) do
    create(:project, :public, topic_list: [source_topic.name, target_topic.name], namespace: namespace)
  end

  subject { described_class.new(source_topic, target_topic).execute }

  describe '#execute' do
    it 'merges source topic into target topic' do
      subject

      expect(target_topic.projects).to contain_exactly(project_1, project_2, project_3, project_4)
      expect { source_topic.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'refreshes counters of target topic' do
      expect { subject }
        .to change { target_topic.reload.total_projects_count }.by(2)
        .and change { target_topic.reload.non_private_projects_count }.by(1)
    end

    context 'when source topic fails to delete' do
      it 'reverts previous changes' do
        allow(source_topic.reload).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

        response = subject
        expect(response).to be_error
        expect(response.message).to eq('Topics could not be merged!')

        expect(source_topic.projects).to contain_exactly(project_1, project_2, project_4)
        expect(target_topic.projects).to contain_exactly(project_3, project_4)
      end
    end

    context 'for parameter validation' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:other_org_topic) do
        create(:topic, name: 'target_topic_from_other_organization', organization: create(:organization))
      end

      subject { described_class.new(source_topic_parameter, target_topic_parameter).execute }

      # rubocop:disable Layout/LineLength -- to preserve the block format
      where(:source_topic_parameter, :target_topic_parameter, :expected_message) do
        nil                | ref(:target_topic)    | 'The source topic is not a topic.'
        ref(:source_topic) | nil                   | 'The target topic is not a topic.'
        ref(:target_topic) | ref(:target_topic)    | 'The source topic and the target topic are identical.'
        ref(:source_topic) | ref(:other_org_topic) | 'The source topic and the target topic must belong to the same organization.'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it 'raises correct error' do
          response = subject
          expect(response).to be_error
          expect(response.message).to eq(expected_message)
        end
      end
    end
  end
end
