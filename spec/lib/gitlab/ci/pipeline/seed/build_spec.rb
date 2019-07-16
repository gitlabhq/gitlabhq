# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Seed::Build do
  let(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:attributes) { { name: 'rspec', ref: 'master' } }

  let(:seed_build) { described_class.new(pipeline, attributes) }

  describe '#attributes' do
    subject { seed_build.attributes }

    it { is_expected.to be_a(Hash) }
    it { is_expected.to include(:name, :project, :ref) }
  end

  describe '#bridge?' do
    subject { seed_build.bridge? }

    context 'when job is a bridge' do
      let(:attributes) do
        { name: 'rspec', ref: 'master', options: { trigger: 'my/project' } }
      end

      it { is_expected.to be_truthy }
    end

    context 'when trigger definition is empty' do
      let(:attributes) do
        { name: 'rspec', ref: 'master', options: { trigger: '' } }
      end

      it { is_expected.to be_falsey }
    end

    context 'when job is not a bridge' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#to_resource' do
    subject { seed_build.to_resource }

    context 'when job is not a bridge' do
      it { is_expected.to be_a(::Ci::Build) }
      it { is_expected.to be_valid }
    end

    context 'when job is a bridge' do
      let(:attributes) do
        { name: 'rspec', ref: 'master', options: { trigger: 'my/project' } }
      end

      it { is_expected.to be_a(::Ci::Bridge) }
      it { is_expected.to be_valid }
    end

    it 'memoizes a resource object' do
      expect(subject.object_id).to eq seed_build.to_resource.object_id
    end

    it 'can not be persisted without explicit assignment' do
      pipeline.save!

      expect(subject).not_to be_persisted
    end
  end

  describe 'applying job inclusion policies' do
    subject { seed_build }

    context 'when no branch policy is specified' do
      let(:attributes) do
        { name: 'rspec' }
      end

      it { is_expected.to be_included }
    end

    context 'when branch policy does not match' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: ['deploy'] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: ['deploy'] } }
        end

        it { is_expected.to be_included }
      end

      context 'with both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[deploy] },
            except: { refs: %w[deploy] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when branch regexp policy does not match' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[/^deploy$/] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[/^deploy$/] } }
        end

        it { is_expected.to be_included }
      end

      context 'with both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[/^deploy$/] },
            except: { refs: %w[/^deploy$/] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when branch policy matches' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[deploy master] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[deploy master] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[deploy master] },
            except: { refs: %w[deploy master] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when keyword policy matches' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[branches] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[branches] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[branches] },
            except: { refs: %w[branches] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when keyword policy does not match' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[tags] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[tags] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[tags] },
            except: { refs: %w[tags] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'with source-keyword policy' do
      using RSpec::Parameterized

      let(:pipeline) do
        build(:ci_empty_pipeline, ref: 'deploy', tag: false, source: source)
      end

      context 'matches' do
        where(:keyword, :source) do
          [
            %w[pushes push],
            %w[web web],
            %w[triggers trigger],
            %w[schedules schedule],
            %w[api api],
            %w[external external]
          ]
        end

        with_them do
          context 'using an only policy' do
            let(:attributes) do
              { name: 'rspec', only: { refs: [keyword] } }
            end

            it { is_expected.to be_included }
          end

          context 'using an except policy' do
            let(:attributes) do
              { name: 'rspec', except: { refs: [keyword] } }
            end

            it { is_expected.not_to be_included }
          end

          context 'using both only and except policies' do
            let(:attributes) do
              {
                name: 'rspec',
                only: { refs: [keyword] },
                except: { refs: [keyword] }
              }
            end

            it { is_expected.not_to be_included }
          end
        end
      end

      context 'non-matches' do
        where(:keyword, :source) do
          %w[web trigger schedule api external].map  { |source| ['pushes', source] } +
          %w[push trigger schedule api external].map { |source| ['web', source] } +
          %w[push web schedule api external].map { |source| ['triggers', source] } +
          %w[push web trigger api external].map { |source| ['schedules', source] } +
          %w[push web trigger schedule external].map { |source| ['api', source] } +
          %w[push web trigger schedule api].map { |source| ['external', source] }
        end

        with_them do
          context 'using an only policy' do
            let(:attributes) do
              { name: 'rspec', only: { refs: [keyword] } }
            end

            it { is_expected.not_to be_included }
          end

          context 'using an except policy' do
            let(:attributes) do
              { name: 'rspec', except: { refs: [keyword] } }
            end

            it { is_expected.to be_included }
          end

          context 'using both only and except policies' do
            let(:attributes) do
              {
                name: 'rspec',
                only: { refs: [keyword] },
                except: { refs: [keyword] }
              }
            end

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

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: ["branches@#{pipeline.project_full_path}"] },
            except: { refs: ["branches@#{pipeline.project_full_path}"] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when repository path does not matches' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[branches@fork] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[branches@fork] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[branches@fork] },
            except: { refs: %w[branches@fork] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end
  end
end
