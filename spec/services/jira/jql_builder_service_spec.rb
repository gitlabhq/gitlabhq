# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jira::JqlBuilderService do
  describe '#execute' do
    subject { described_class.new('PROJECT_KEY', params).execute }

    context 'when no params' do
      let(:params) { {} }

      it 'builds jql with default ordering' do
        expect(subject).to eq('project = PROJECT_KEY order by created DESC')
      end
    end

    context 'with search param' do
      let(:params) { { search: 'new issue' } }

      it 'builds jql' do
        expect(subject).to eq("project = PROJECT_KEY AND (summary ~ \"new issue\" OR description ~ \"new issue\") order by created DESC")
      end

      context 'search param with single qoutes' do
        let(:params) { { search: "new issue's" } }

        it 'builds jql' do
          expect(subject).to eq("project = PROJECT_KEY AND (summary ~ \"new issue's\" OR description ~ \"new issue's\") order by created DESC")
        end
      end

      context 'search param with single double qoutes' do
        let(:params) { { search: '"one \"more iss\'ue"' } }

        it 'builds jql' do
          expect(subject).to eq("project = PROJECT_KEY AND (summary ~ \"one more iss'ue\" OR description ~ \"one more iss'ue\") order by created DESC")
        end
      end

      context 'search param with special characters' do
        let(:params) { { search: 'issues' + Jira::JqlBuilderService::JQL_SPECIAL_CHARS.join(" AND ") } }

        it 'builds jql' do
          expect(subject).to eq("project = PROJECT_KEY AND (summary ~ \"issues and and and and and and and and and and and and and and and and\" OR description ~ \"issues and and and and and and and and and and and and and and and and\") order by created DESC")
        end
      end
    end

    context 'with labels param' do
      let(:params) { { labels: ['label1', 'label2', "\"'try\"some'more\"quote'here\""] } }

      it 'builds jql' do
        expect(subject).to eq("project = PROJECT_KEY AND labels = \"label1\" AND labels = \"label2\" AND labels = \"\\\"'try\\\"some'more\\\"quote'here\\\"\" order by created DESC")
      end
    end

    context 'with status param' do
      let(:params) { { status: "\"'try\"some'more\"quote'here\"" } }

      it 'builds jql' do
        expect(subject).to eq("project = PROJECT_KEY AND status = \"\\\"'try\\\"some'more\\\"quote'here\\\"\" order by created DESC")
      end
    end

    context 'with author_username param' do
      let(:params) { { author_username: "\"'try\"some'more\"quote'here\"" } }

      it 'builds jql' do
        expect(subject).to eq("project = PROJECT_KEY AND reporter = \"\\\"'try\\\"some'more\\\"quote'here\\\"\" order by created DESC")
      end
    end

    context 'with assignee_username param' do
      let(:params) { { assignee_username: "\"'try\"some'more\"quote'here\"" } }

      it 'builds jql' do
        expect(subject).to eq("project = PROJECT_KEY AND assignee = \"\\\"'try\\\"some'more\\\"quote'here\\\"\" order by created DESC")
      end
    end

    context 'with sort params' do
      let(:params) { { sort: 'updated', sort_direction: 'ASC' } }

      it 'builds jql' do
        expect(subject).to eq('project = PROJECT_KEY order by updated ASC')
      end
    end
  end
end
