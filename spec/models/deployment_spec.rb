require 'spec_helper'

describe Deployment, models: true do
  subject { build(:deployment) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:environment) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:deployable) }

  it { is_expected.to delegate_method(:name).to(:environment).with_prefix }
  it { is_expected.to delegate_method(:commit).to(:project) }
  it { is_expected.to delegate_method(:commit_title).to(:commit).as(:try) }
  it { is_expected.to delegate_method(:manual_actions).to(:deployable).as(:try) }

  it { is_expected.to validate_presence_of(:ref) }
  it { is_expected.to validate_presence_of(:sha) }

  describe '#deployed_to?' do
    let(:project)     { create(:project) }
    let(:environment) { create(:environment, project: project) }
    let(:deployment) do
      create(:deployment, environment: environment, sha: '5f923865dde3436854e9ceb9cdb7815618d4e849')
    end

    context 'when there is no project commit' do
      it 'returns false' do
        expect(deployment.deployed_to?('random-branch')).to be false
      end
    end

    context 'when they share the same tree branch' do
      it 'returns true' do
        expect(deployment.deployed_to?('HEAD')).to be true
      end
    end
  end
end
