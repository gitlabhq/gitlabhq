# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::WebHooksHelper do
  let_it_be_with_reload(:project) { create(:project) }

  let(:current_user) { nil }
  let(:callout_dismissed) { false }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
    allow(helper).to receive(:web_hook_disabled_dismissed?).with(project).and_return(callout_dismissed)
  end

  shared_context 'user is logged in' do
    let(:current_user) { create(:user) }
  end

  shared_context 'the user has permission' do
    before do
      project.add_maintainer(current_user)
    end
  end

  shared_context 'the user dismissed the callout' do
    let(:callout_dismissed) { true }
  end

  shared_context 'a hook has failed' do
    before do
      create(:project_hook, :permanently_disabled, project: project)
    end
  end

  describe '#show_project_hook_failed_callout?' do
    context 'all conditions are met' do
      include_context 'user is logged in'
      include_context 'the user has permission'
      include_context 'a hook has failed'

      it 'is true' do
        expect(helper).to be_show_project_hook_failed_callout(project: project)
      end

      it 'caches the DB calls until the TTL', :use_clean_rails_memory_store_caching, :request_store do
        helper.show_project_hook_failed_callout?(project: project)

        travel_to((described_class::EXPIRY_TTL - 1.second).from_now) do
          expect do
            helper.show_project_hook_failed_callout?(project: project)
          end.not_to exceed_query_limit(0)
        end

        travel_to((described_class::EXPIRY_TTL + 1.second).from_now) do
          expect do
            helper.show_project_hook_failed_callout?(project: project)
          end.to exceed_query_limit(0)
        end
      end
    end

    context 'one condition is not met' do
      contexts = [
        'user is logged in',
        'the user has permission',
        'a hook has failed'
      ]

      contexts.each do |name|
        context "namely #{name}" do
          contexts.each { |ctx| include_context(ctx) unless ctx == name }

          it 'is false' do
            expect(helper).not_to be_show_project_hook_failed_callout(project: project)
          end
        end
      end
    end
  end
end
