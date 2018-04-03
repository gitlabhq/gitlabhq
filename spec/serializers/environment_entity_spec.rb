require 'spec_helper'

describe EnvironmentEntity do
  let(:entity) do
    described_class.new(environment, request: double)
  end

  let(:environment) { create(:environment) }
  subject { entity.as_json }

  it 'exposes latest deployment' do
    expect(subject).to include(:last_deployment)
  end

  it 'exposes core elements of environment' do
    expect(subject).to include(:id, :name, :state, :environment_path)
  end

  it 'exposes folder path' do
    expect(subject).to include(:folder_path)
  end

  describe 'scaling' do
    context 'when environment has scaling' do
      before do
        create(:environment_scaling, environment: environment)
      end
      it 'exposes scaling' do
        expect(subject).to include(:scaling)
      end
    end

    context 'when environment does not have scaling' do
      it 'does not expose scaling' do
        expect(subject).not_to include(:scaling)
      end
    end
  end

  context 'metrics disabled' do
    before do
      allow(environment).to receive(:has_metrics?).and_return(false)
    end

    it "doesn't expose metrics path" do
      expect(subject).not_to include(:metrics_path)
    end
  end

  context 'metrics enabled' do
    before do
      allow(environment).to receive(:has_metrics?).and_return(true)
    end

    it 'exposes metrics path' do
      expect(subject).to include(:metrics_path)
    end
  end
end
