# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::LabelHelpers do
  describe 'create_service_params' do
    let(:label_helper) do
      Class.new do
        include API::Helpers::LabelHelpers
      end.new
    end

    context 'when a project is given' do
      it 'returns the expected params' do
        project = create(:project)
        expect(label_helper.create_service_params(project)).to eq({ project: project })
      end
    end

    context 'when a group is given' do
      it 'returns the expected params' do
        group = create(:group)
        expect(label_helper.create_service_params(group)).to eq({ group: group })
      end
    end

    context 'when something else is given' do
      it 'raises a type error' do
        expect { label_helper.create_service_params(Class.new) }.to raise_error(TypeError)
      end
    end
  end
end
