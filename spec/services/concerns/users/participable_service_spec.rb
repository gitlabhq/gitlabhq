# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ParticipableService, feature_category: :duo_agent_platform do
  describe '#participation_object' do
    subject(:participation_object) { service.send(:participation_object) }

    context 'when not implemented' do
      let(:service_class) do
        Class.new do
          include ::Users::ParticipableService
        end
      end

      let(:service) { service_class.new }

      it 'raises NotImplementedError' do
        expect { participation_object }.to raise_error(NotImplementedError)
      end
    end

    context 'when implemented' do
      let(:project) { instance_double(::Project) }
      let(:service_class) do
        Class.new do
          include ::Users::ParticipableService

          attr_reader :participation_object

          def initialize(participation_object = nil)
            @participation_object = participation_object
          end
        end
      end

      let(:service) { service_class.new(project) }

      it 'returns the related object' do
        expect(participation_object).to eq(project)
      end
    end
  end
end
