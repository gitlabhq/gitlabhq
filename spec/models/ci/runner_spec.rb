require 'spec_helper'

describe Ci::Runner, models: true do
  describe 'validation' do
    context 'when runner is not allowed to pick untagged jobs' do
      context 'when runner does not have tags' do
        it 'is not valid' do
          runner = build(:ci_runner, tag_list: [], run_untagged: false)
          expect(runner).to be_invalid
        end
      end

      context 'when runner has tags' do
        it 'is valid' do
          runner = build(:ci_runner, tag_list: ['tag'], run_untagged: false)
          expect(runner).to be_valid
        end
      end
    end
  end

  describe '#display_name' do
    it 'returns the description if it has a value' do
      runner = FactoryGirl.build(:ci_runner, description: 'Linux/Ruby-1.9.3-p448')
      expect(runner.display_name).to eq 'Linux/Ruby-1.9.3-p448'
    end

    it 'returns the token if it does not have a description' do
      runner = FactoryGirl.create(:ci_runner)
      expect(runner.display_name).to eq runner.description
    end

    it 'returns the token if the description is an empty string' do
      runner = FactoryGirl.build(:ci_runner, description: '', token: 'token')
      expect(runner.display_name).to eq runner.token
    end
  end

  describe '#assign_to' do
    let!(:project) { FactoryGirl.create :empty_project }
    let!(:shared_runner) { FactoryGirl.create(:ci_runner, :shared) }

    before do
      shared_runner.assign_to(project)
    end

    it { expect(shared_runner).to be_specific }
    it { expect(shared_runner.projects).to eq([project]) }
    it { expect(shared_runner.only_for?(project)).to be_truthy }
  end

  describe '.online' do
    subject { Ci::Runner.online }

    before do
      @runner1 = FactoryGirl.create(:ci_runner, :shared, contacted_at: 1.year.ago)
      @runner2 = FactoryGirl.create(:ci_runner, :shared, contacted_at: 1.second.ago)
    end

    it { is_expected.to eq([@runner2])}
  end

  describe '#online?' do
    let(:runner) { FactoryGirl.create(:ci_runner, :shared) }

    subject { runner.online? }

    context 'never contacted' do
      before do
        runner.contacted_at = nil
      end

      it { is_expected.to be_falsey }
    end

    context 'contacted long time ago time' do
      before do
        runner.contacted_at = 1.year.ago
      end

      it { is_expected.to be_falsey }
    end

    context 'contacted 1s ago' do
      before do
        runner.contacted_at = 1.second.ago
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#can_pick?' do
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, pipeline: pipeline) }
    let(:runner) { create(:ci_runner) }

    before do
      build.project.runners << runner
    end

    context 'when runner does not have tags' do
      it 'can handle builds without tags' do
        expect(runner.can_pick?(build)).to be_truthy
      end

      it 'cannot handle build with tags' do
        build.tag_list = ['aa']

        expect(runner.can_pick?(build)).to be_falsey
      end
    end

    context 'when runner has tags' do
      before do
        runner.tag_list = ['bb', 'cc']
      end

      shared_examples 'tagged build picker' do
        it 'can handle build with matching tags' do
          build.tag_list = ['bb']

          expect(runner.can_pick?(build)).to be_truthy
        end

        it 'cannot handle build without matching tags' do
          build.tag_list = ['aa']

          expect(runner.can_pick?(build)).to be_falsey
        end
      end

      context 'when runner can pick untagged jobs' do
        it 'can handle builds without tags' do
          expect(runner.can_pick?(build)).to be_truthy
        end

        it_behaves_like 'tagged build picker'
      end

      context 'when runner cannot pick untagged jobs' do
        before do
          runner.run_untagged = false
        end

        it 'cannot handle builds without tags' do
          expect(runner.can_pick?(build)).to be_falsey
        end

        it_behaves_like 'tagged build picker'
      end
    end

    context 'when runner is locked' do
      before do
        runner.locked = true
      end

      shared_examples 'locked build picker' do
        context 'when runner cannot pick untagged jobs' do
          before do
            runner.run_untagged = false
          end

          it 'cannot handle builds without tags' do
            expect(runner.can_pick?(build)).to be_falsey
          end
        end

        context 'when having runner tags' do
          before do
            runner.tag_list = ['bb', 'cc']
          end

          it 'cannot handle it for builds without matching tags' do
            build.tag_list = ['aa']

            expect(runner.can_pick?(build)).to be_falsey
          end
        end
      end

      context 'when serving the same project' do
        it 'can handle it' do
          expect(runner.can_pick?(build)).to be_truthy
        end

        it_behaves_like 'locked build picker'

        context 'when having runner tags' do
          before do
            runner.tag_list = ['bb', 'cc']
            build.tag_list = ['bb']
          end

          it 'can handle it for matching tags' do
            expect(runner.can_pick?(build)).to be_truthy
          end
        end
      end

      context 'serving a different project' do
        before do
          runner.runner_projects.destroy_all
        end

        it 'cannot handle it' do
          expect(runner.can_pick?(build)).to be_falsey
        end

        it_behaves_like 'locked build picker'

        context 'when having runner tags' do
          before do
            runner.tag_list = ['bb', 'cc']
            build.tag_list = ['bb']
          end

          it 'cannot handle it for matching tags' do
            expect(runner.can_pick?(build)).to be_falsey
          end
        end
      end
    end
  end

  describe '#status' do
    let(:runner) { FactoryGirl.create(:ci_runner, :shared, contacted_at: 1.second.ago) }

    subject { runner.status }

    context 'never connected' do
      before do
        runner.contacted_at = nil
      end

      it { is_expected.to eq(:not_connected) }
    end

    context 'contacted 1s ago' do
      before do
        runner.contacted_at = 1.second.ago
      end

      it { is_expected.to eq(:online) }
    end

    context 'contacted long time ago' do
      before do
        runner.contacted_at = 1.year.ago
      end

      it { is_expected.to eq(:offline) }
    end

    context 'inactive' do
      before do
        runner.active = false
      end

      it { is_expected.to eq(:paused) }
    end
  end

  describe '.assignable_for' do
    let(:runner) { create(:ci_runner) }
    let(:project) { create(:project) }
    let(:another_project) { create(:project) }

    before do
      project.runners << runner
    end

    context 'with shared runners' do
      before do
        runner.update(is_shared: true)
      end

      context 'does not give owned runner' do
        subject { Ci::Runner.assignable_for(project) }

        it { is_expected.to be_empty }
      end

      context 'does not give shared runner' do
        subject { Ci::Runner.assignable_for(another_project) }

        it { is_expected.to be_empty }
      end
    end

    context 'with unlocked runner' do
      context 'does not give owned runner' do
        subject { Ci::Runner.assignable_for(project) }

        it { is_expected.to be_empty }
      end

      context 'does give a specific runner' do
        subject { Ci::Runner.assignable_for(another_project) }

        it { is_expected.to contain_exactly(runner) }
      end
    end

    context 'with locked runner' do
      before do
        runner.update(locked: true)
      end

      context 'does not give owned runner' do
        subject { Ci::Runner.assignable_for(project) }

        it { is_expected.to be_empty }
      end

      context 'does not give a locked runner' do
        subject { Ci::Runner.assignable_for(another_project) }

        it { is_expected.to be_empty }
      end
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

  describe '#has_tags?' do
    context 'when runner has tags' do
      subject { create(:ci_runner, tag_list: ['tag']) }
      it { is_expected.to have_tags }
    end

    context 'when runner does not have tags' do
      subject { create(:ci_runner, tag_list: []) }
      it { is_expected.not_to have_tags }
    end
  end

  describe '.search' do
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
