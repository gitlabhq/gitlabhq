# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jira::JqlBuilderService do
  describe '#execute' do
    subject { described_class.new('PROJECT_KEY', params).execute }

    context 'when no params' do
      let(:params) { {} }

      it 'builds jql with default ordering' do
        expect(subject).to eq("project = PROJECT_KEY order by created DESC")
      end
    end

    context 'with sort params' do
      let(:params) { { sort: 'updated', sort_direction: 'ASC' } }

      it 'builds jql' do
        expect(subject).to eq("project = PROJECT_KEY order by updated ASC")
      end
    end
  end
end
