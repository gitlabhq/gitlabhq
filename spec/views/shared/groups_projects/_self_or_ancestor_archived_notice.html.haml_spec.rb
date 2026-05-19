# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/groups_projects/_self_or_ancestor_archived_notice.html.haml',
  feature_category: :groups_and_projects do
  describe 'render' do
    context 'when context is nil' do
      it 'renders nothing' do
        output = view.render 'shared/groups_projects/self_or_ancestor_archived_notice', context: nil

        expect(output).to be_nil
      end
    end

    context 'when context is defined' do
      let_it_be(:context) { build_stubbed(:group) }

      context 'when self and ancestors not archived' do
        before do
          allow(context).to receive(:self_or_ancestors_archived?).and_return(false)
        end

        it 'renders nothing' do
          output = view.render 'shared/groups_projects/self_or_ancestor_archived_notice', context: context

          expect(output).to be_nil
        end
      end

      context 'when self or ancestors archived' do
        let_it_be(:banner_message) { 'sample message' }
        let_it_be(:banner_message_mobile) { 'sample mobile message' }

        before do
          allow(context).to receive(:self_or_ancestors_archived?).and_return(true)
          allow(view).to receive_messages(
            archived_banner_message: banner_message,
            archived_banner_message_mobile: banner_message_mobile
          )
        end

        it 'renders alert with desktop banner message hidden on mobile' do
          render 'shared/groups_projects/self_or_ancestor_archived_notice', context: context

          expect(rendered).to have_css('.gl-alert span.gl-hidden.\\@md\\/content-panels\\:gl-inline',
            text: banner_message)
        end

        it 'renders alert with mobile banner message hidden on desktop' do
          render 'shared/groups_projects/self_or_ancestor_archived_notice', context: context

          expect(rendered).to have_css('.gl-alert span.\\@md\\/content-panels\\:gl-hidden', text: banner_message_mobile)
        end
      end
    end
  end
end
