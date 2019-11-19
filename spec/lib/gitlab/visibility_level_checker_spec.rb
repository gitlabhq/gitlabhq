# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::VisibilityLevelChecker do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:visibility_level_checker) { }
  let(:override_params) { {} }

  subject { described_class.new(user, project, project_params: override_params) }

  describe '#level_restricted?' do
    context 'when visibility level is allowed' do
      it 'returns false with nil for visibility level' do
        result = subject.level_restricted?

        expect(result.restricted?).to eq(false)
        expect(result.visibility_level).to be_nil
      end
    end

    context 'when visibility level is restricted' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      it 'returns true and visibility name' do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        result = subject.level_restricted?

        expect(result.restricted?).to eq(true)
        expect(result.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
      end

      context 'overridden visibility' do
        let(:override_params) do
          {
            import_data: {
              data: {
                override_params: {
                  visibility: override_visibility
                }
              }
            }
          }
        end

        context 'when restricted' do
          let(:override_visibility) { 'public' }

          it 'returns true and visibility name' do
            result = subject.level_restricted?

            expect(result.restricted?).to eq(true)
            expect(result.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
          end
        end

        context 'when misspelled' do
          let(:override_visibility) { 'publik' }

          it 'returns false with nil for visibility level' do
            result = subject.level_restricted?

            expect(result.restricted?).to eq(false)
            expect(result.visibility_level).to be_nil
          end
        end

        context 'when import_data is missing' do
          let(:override_params) { {} }

          it 'returns false with nil for visibility level' do
            result = subject.level_restricted?

            expect(result.restricted?).to eq(false)
            expect(result.visibility_level).to be_nil
          end
        end
      end
    end
  end
end
