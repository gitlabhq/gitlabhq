# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::VisibilityLevelChecker do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:override_params) { {} }

  describe '#level_restricted?' do
    subject(:result) { described_class.new(user, project, project_params: override_params).level_restricted? }

    context 'when visibility level is allowed' do
      it 'returns false with nil for visibility level' do
        expect(result.restricted?).to eq(false)
        expect(result.visibility_level).to be_nil
      end
    end

    context 'when visibility level is restricted' do
      before do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
      end

      context 'for public project' do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        context 'for non-admin user' do
          it 'returns true and visibility name' do
            expect(result.restricted?).to eq(true)
            expect(result.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
          end
        end

        context 'for admin user' do
          let(:user) { create(:user, :admin) }

          it 'returns false and a nil visibility level' do
            expect(result.restricted?).to eq(false)
            expect(result.visibility_level).to be_nil
          end
        end
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
            expect(result.restricted?).to eq(true)
            expect(result.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
          end
        end

        context 'when misspelled' do
          let(:override_visibility) { 'publik' }

          it 'returns false with nil for visibility level' do
            expect(result.restricted?).to eq(false)
            expect(result.visibility_level).to be_nil
          end
        end

        context 'when import_data is missing' do
          let(:override_params) { {} }

          it 'returns false with nil for visibility level' do
            expect(result.restricted?).to eq(false)
            expect(result.visibility_level).to be_nil
          end
        end
      end
    end
  end
end
