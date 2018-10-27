require 'spec_helper'

describe Gitlab::Ci::Pipeline::Seed::Build do
  let(:pipeline) { create(:ci_empty_pipeline) }

  let(:attributes) do
    { name: 'rspec',
      ref: 'master',
      commands: 'rspec' }
  end

  subject do
    described_class.new(pipeline, attributes)
  end

  describe '#parallel?' do
    context 'when build is not parallelized' do
      it 'should be false' do
        expect(subject.parallel?).to eq(false)
      end
    end

    context 'when build is parallelized' do
      before do
        attributes[:options] = { parallel: 5 }
      end

      it 'should be true' do
        expect(subject.parallel?).to eq(true)
      end
    end
  end

  describe '#parallelize_build' do
    let(:total) { 5 }

    before do
      attributes[:options] = { parallel: total }
    end

    it 'returns duplicated builds' do
      builds = subject.parallelize_build

      expect(builds.size).to eq(total)
    end

    it 'returns builds with indexed names' do
      builds = subject.parallelize_build

      base_name = builds.first.name.split(' ')[0]
      names = builds.map(&:name)
      expect(names).to all(match(%r{^#{base_name} \d+/\d+$}))
    end
  end

  describe '#attributes' do
    it 'returns hash attributes of a build' do
      expect(subject.attributes).to be_a Hash
      expect(subject.attributes)
        .to include(:name, :project, :ref, :commands)
    end
  end

  describe '#to_resource' do
    context 'when build is not parallelized' do
      it 'returns a valid build resource' do
        expect(subject.to_resource).to be_a(::Ci::Build)
        expect(subject.to_resource).to be_valid
      end
    end

    context 'when build is parallelized' do
      before do
        attributes[:options] = { parallel: 5 }
      end

      it 'returns a group of valid build resources' do
        expect(subject.to_resource).to all(be_a(::Ci::Build))
        expect(subject.to_resource).to all(be_valid)
      end
    end

    it 'memoizes a resource object' do
      build = subject.to_resource

      expect(build.object_id).to eq subject.to_resource.object_id
    end

    it 'can not be persisted without explicit assignment' do
      build = subject.to_resource

      pipeline.save!

      expect(build).not_to be_persisted
    end
  end

  describe 'applying only/except policies' do
    context 'when no branch policy is specified' do
      let(:attributes) { { name: 'rspec' } }

      it { is_expected.to be_included }
    end

    context 'when branch policy does not match' do
      context 'when using only' do
        let(:attributes) { { name: 'rspec', only: { refs: ['deploy'] } } }

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) { { name: 'rspec', except: { refs: ['deploy'] } } }

        it { is_expected.to be_included }
      end
    end

    context 'when branch regexp policy does not match' do
      context 'when using only' do
        let(:attributes) { { name: 'rspec', only: { refs: ['/^deploy$/'] } } }

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) { { name: 'rspec', except: { refs: ['/^deploy$/'] } } }

        it { is_expected.to be_included }
      end
    end

    context 'when branch policy matches' do
      context 'when using only' do
        let(:attributes) { { name: 'rspec', only: { refs: %w[deploy master] } } }

        it { is_expected.to be_included }
      end

      context 'when using except' do
        let(:attributes) { { name: 'rspec', except: { refs: %w[deploy master] } } }

        it { is_expected.not_to be_included }
      end
    end

    context 'when keyword policy matches' do
      context 'when using only' do
        let(:attributes) { { name: 'rspec', only: { refs: ['branches'] } } }

        it { is_expected.to be_included }
      end

      context 'when using except' do
        let(:attributes) { { name: 'rspec', except: { refs: ['branches'] } } }

        it { is_expected.not_to be_included }
      end
    end

    context 'when keyword policy does not match' do
      context 'when using only' do
        let(:attributes) { { name: 'rspec', only: { refs: ['tags'] } } }

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) { { name: 'rspec', except: { refs: ['tags'] } } }

        it { is_expected.to be_included }
      end
    end

    context 'when keywords and pipeline source policy matches' do
      possibilities = [%w[pushes push],
                       %w[web web],
                       %w[triggers trigger],
                       %w[schedules schedule],
                       %w[api api],
                       %w[external external]]

      context 'when using only' do
        possibilities.each do |keyword, source|
          context "when using keyword `#{keyword}` and source `#{source}`" do
            let(:pipeline) do
              build(:ci_empty_pipeline, ref: 'deploy', tag: false, source: source)
            end

            let(:attributes) { { name: 'rspec', only: { refs: [keyword] } } }

            it { is_expected.to be_included }
          end
        end
      end

      context 'when using except' do
        possibilities.each do |keyword, source|
          context "when using keyword `#{keyword}` and source `#{source}`" do
            let(:pipeline) do
              build(:ci_empty_pipeline, ref: 'deploy', tag: false, source: source)
            end

            let(:attributes) { { name: 'rspec', except: { refs: [keyword] } } }

            it { is_expected.not_to be_included }
          end
        end
      end
    end

    context 'when keywords and pipeline source does not match' do
      possibilities = [%w[pushes web],
                       %w[web push],
                       %w[triggers schedule],
                       %w[schedules external],
                       %w[api trigger],
                       %w[external api]]

      context 'when using only' do
        possibilities.each do |keyword, source|
          context "when using keyword `#{keyword}` and source `#{source}`" do
            let(:pipeline) do
              build(:ci_empty_pipeline, ref: 'deploy', tag: false, source: source)
            end

            let(:attributes) { { name: 'rspec', only: { refs: [keyword] } } }

            it { is_expected.not_to be_included }
          end
        end
      end

      context 'when using except' do
        possibilities.each do |keyword, source|
          context "when using keyword `#{keyword}` and source `#{source}`" do
            let(:pipeline) do
              build(:ci_empty_pipeline, ref: 'deploy', tag: false, source: source)
            end

            let(:attributes) { { name: 'rspec', except: { refs: [keyword] } } }

            it { is_expected.to be_included }
          end
        end
      end
    end

    context 'when repository path matches' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: ["branches@#{pipeline.project_full_path}"] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: ["branches@#{pipeline.project_full_path}"] } }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when repository path does not matches' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: ['branches@fork'] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: ['branches@fork'] } }
        end

        it { is_expected.to be_included }
      end
    end
  end
end
