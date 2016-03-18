# == Schema Information
#
# Table name: ci_runners
#
#  id           :integer          not null, primary key
#  token        :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  description  :string(255)
#  contacted_at :datetime
#  active       :boolean          default(TRUE), not null
#  is_shared    :boolean          default(FALSE)
#  name         :string(255)
#  version      :string(255)
#  revision     :string(255)
#  platform     :string(255)
#  architecture :string(255)
#

require 'spec_helper'

describe Ci::Runner, models: true do
  describe '#display_name' do
    it 'should return the description if it has a value' do
      runner = FactoryGirl.build(:ci_runner, description: 'Linux/Ruby-1.9.3-p448')
      expect(runner.display_name).to eq 'Linux/Ruby-1.9.3-p448'
    end

    it 'should return the token if it does not have a description' do
      runner = FactoryGirl.create(:ci_runner)
      expect(runner.display_name).to eq runner.description
    end

    it 'should return the token if the description is an empty string' do
      runner = FactoryGirl.build(:ci_runner, description: '', token: 'token')
      expect(runner.display_name).to eq runner.token
    end
  end

  describe :assign_to do
    let!(:project) { FactoryGirl.create :empty_project }
    let!(:shared_runner) { FactoryGirl.create(:ci_runner, :shared) }

    before { shared_runner.assign_to(project) }

    it { expect(shared_runner).to be_specific }
    it { expect(shared_runner.projects).to eq([project]) }
    it { expect(shared_runner.only_for?(project)).to be_truthy }
  end

  describe :online do
    subject { Ci::Runner.online }

    before do
      @runner1 = FactoryGirl.create(:ci_runner, :shared, contacted_at: 1.year.ago)
      @runner2 = FactoryGirl.create(:ci_runner, :shared, contacted_at: 1.second.ago)
    end

    it { is_expected.to eq([@runner2])}
  end

  describe :online? do
    let(:runner) { FactoryGirl.create(:ci_runner, :shared) }

    subject { runner.online? }

    context 'never contacted' do
      before { runner.contacted_at = nil }

      it { is_expected.to be_falsey }
    end

    context 'contacted long time ago time' do
      before { runner.contacted_at = 1.year.ago }

      it { is_expected.to be_falsey }
    end

    context 'contacted 1s ago' do
      before { runner.contacted_at = 1.second.ago }

      it { is_expected.to be_truthy }
    end
  end

  describe :status do
    let(:runner) { FactoryGirl.create(:ci_runner, :shared, contacted_at: 1.second.ago) }

    subject { runner.status }

    context 'never connected' do
      before { runner.contacted_at = nil }

      it { is_expected.to eq(:not_connected) }
    end

    context 'contacted 1s ago' do
      before { runner.contacted_at = 1.second.ago }

      it { is_expected.to eq(:online) }
    end

    context 'contacted long time ago' do
      before { runner.contacted_at = 1.year.ago }

      it { is_expected.to eq(:offline) }
    end

    context 'inactive' do
      before { runner.active = false }

      it { is_expected.to eq(:paused) }
    end
  end

  describe "belongs_to_one_project?" do
    it "returns false if there are two projects runner assigned to" do
      runner = FactoryGirl.create(:ci_runner)
      project = FactoryGirl.create(:empty_project)
      project1 = FactoryGirl.create(:empty_project)
      project.runners << runner
      project1.runners << runner

      expect(runner.belongs_to_one_project?).to be_falsey
    end

    it "returns true" do
      runner = FactoryGirl.create(:ci_runner)
      project = FactoryGirl.create(:empty_project)
      project.runners << runner

      expect(runner.belongs_to_one_project?).to be_truthy
    end
  end

  describe '#search' do
    let(:runner) { create(:ci_runner, token: '123abc') }

    it 'returns runners with a matching token' do
      expect(described_class.search(runner.token)).to eq([runner])
    end

    it 'returns runners with a partially matching token' do
      expect(described_class.search(runner.token[0..2])).to eq([runner])
    end

    it 'returns runners with a matching token regardless of the casing' do
      expect(described_class.search(runner.token.upcase)).to eq([runner])
    end

    it 'returns runners with a matching description' do
      expect(described_class.search(runner.description)).to eq([runner])
    end

    it 'returns runners with a partially matching description' do
      expect(described_class.search(runner.description[0..2])).to eq([runner])
    end

    it 'returns runners with a matching description regardless of the casing' do
      expect(described_class.search(runner.description.upcase)).to eq([runner])
    end
  end
end
