require 'spec_helper'

describe Gitlab::Ci::Pipeline::Seed::Build do
  let(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:attributes) do
    { name: 'rspec', ref: 'master' }
  end

  subject do
    described_class.new(pipeline, attributes)
  end

  describe '#attributes' do
    it 'returns hash attributes of a build' do
      expect(subject.attributes).to be_a Hash
      expect(subject.attributes)
        .to include(:name, :project, :ref)
    end
  end

  describe '#bridge?' do
    context 'when job is a bridge' do
      let(:attributes) do
        { name: 'rspec', ref: 'master', options: { trigger: 'my/project' } }
      end

      it { is_expected.to be_bridge }
    end

    context 'when trigger definition is empty' do
      let(:attributes) do
        { name: 'rspec', ref: 'master', options: { trigger: '' } }
      end

      it { is_expected.not_to be_bridge }
    end

    context 'when job is not a bridge' do
      it { is_expected.not_to be_bridge }
    end
  end

  describe '#to_resource' do
    context 'when job is not a bridge' do
      it 'returns a valid build resource' do
        expect(subject.to_resource).to be_a(::Ci::Build)
        expect(subject.to_resource).to be_valid
      end
    end

    context 'when job is a bridge' do
      let(:attributes) do
        { name: 'rspec', ref: 'master', options: { trigger: 'my/project' } }
      end

      it 'returns a valid bridge resource' do
        expect(subject.to_resource).to be_a(::Ci::Bridge)
        expect(subject.to_resource).to be_valid
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

    context 'with source-keyword policy' do
      using RSpec::Parameterized

      let(:pipeline) { build(:ci_empty_pipeline, ref: 'deploy', tag: false, source: source) }

      context 'matches' do
        where(:keyword, :source) do
          [
            %w(pushes push),
            %w(web web),
            %w(triggers trigger),
            %w(schedules schedule),
            %w(api api),
            %w(external external)
          ]
        end

        with_them do
          context 'using an only policy' do
            let(:attributes) { { name: 'rspec', only: { refs: [keyword] } } }

            it { is_expected.to be_included }
          end

          context 'using an except policy' do
            let(:attributes) { { name: 'rspec', except: { refs: [keyword] } } }

            it { is_expected.not_to be_included }
          end

          context 'using both only and except policies' do
            let(:attributes) { { name: 'rspec', only: { refs: [keyword] }, except: { refs: [keyword] } } }

            it { is_expected.not_to be_included }
          end
        end
      end

      context 'non-matches' do
        where(:keyword, :source) do
          %w(web trigger schedule api external).map { |source| ['pushes', source] } +
          %w(push trigger schedule api external).map { |source| ['web', source] } +
          %w(push web schedule api external).map { |source| ['triggers', source] } +
          %w(push web trigger api external).map { |source| ['schedules', source] } +
          %w(push web trigger schedule external).map { |source| ['api', source] } +
          %w(push web trigger schedule api).map { |source| ['external', source] }
        end

        with_them do
          context 'using an only policy' do
            let(:attributes) { { name: 'rspec', only: { refs: [keyword] } } }

            it { is_expected.not_to be_included }
          end

          context 'using an except policy' do
            let(:attributes) { { name: 'rspec', except: { refs: [keyword] } } }

            it { is_expected.to be_included }
          end

          context 'using both only and except policies' do
            let(:attributes) { { name: 'rspec', only: { refs: [keyword] }, except: { refs: [keyword] } } }

            it { is_expected.not_to be_included }
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
