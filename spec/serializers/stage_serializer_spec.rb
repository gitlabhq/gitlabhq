# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StageSerializer do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:resource) { create(:ci_stage) }

  let(:serializer) do
    described_class.new(current_user: user, project: project)
  end

  subject { serializer.represent(resource) }

  describe '#represent' do
    context 'with a single entity' do
      it 'serializes the stage object' do
        expect(subject[:name]).to eq(resource.name)
      end
    end

    context 'with an array of entities' do
      let(:resource) { create_list(:ci_stage, 2) }

      it 'serializes the array of pipelines' do
        expect(subject).not_to be_empty
      end
    end
  end
end
