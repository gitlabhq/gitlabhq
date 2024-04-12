# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::DestroyService, feature_category: :continuous_delivery do
  include CreateEnvironmentsHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    subject { service.execute(environment) }

    let_it_be(:project) { create(:project, :private, :repository) }
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }

    let(:user) { developer }

    let!(:environment) { create(:environment, project: project, state: :stopped) }

    context "when destroy is authorized" do
      it 'destroys the environment' do
        expect { subject }.to change { environment.destroyed? }.from(false).to(true)
      end
    end

    context "when destroy is not authorized" do
      let(:user) { reporter }

      it 'does not destroy the environment' do
        expect { subject }.not_to change { environment.destroyed? }
      end
    end

    context "when destroy fails" do
      before do
        allow(environment)
          .to receive(:destroy)
          .and_return(false)
      end

      it 'returns errors' do
        expect(subject.message).to include("Attempted to destroy the environment but failed")
      end
    end
  end
end
