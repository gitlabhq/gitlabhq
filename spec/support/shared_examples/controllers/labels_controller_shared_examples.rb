# frozen_string_literal: true

RSpec.shared_examples 'lock_on_merge when editing labels' do
  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(enforce_locked_labels_on_merge: false)
      visit edit_label_path_unlocked
    end

    it 'does not display the checkbox/help text' do
      expect(page).not_to have_content(_('Lock label after a merge request is merged'))
      expect(page).not_to have_content(label_lock_on_merge_help_text)
    end
  end

  it 'updates lock_on_merge' do
    expect(page).to have_content(_('Lock label after a merge request is merged'))
    expect(page).to have_content(label_lock_on_merge_help_text)

    check(_('Lock label after a merge request is merged'))
    click_button 'Save changes'

    expect(label_unlocked.reload.lock_on_merge).to be_truthy
  end

  it 'checkbox is disabled if lock_on_merge already set' do
    visit edit_label_path_locked

    expect(page.find('#label_lock_on_merge')).to be_disabled
  end
end

RSpec.shared_examples 'lock_on_merge when creating labels' do
  it 'is not supported when creating a label' do
    expect(page).not_to have_content(_('Lock label after a merge request is merged'))
    expect(page).not_to have_content(label_lock_on_merge_help_text)
  end
end

RSpec.shared_examples 'handles archived labels' do
  subject(:list_labels_with_archive) do
    get :index, params: params.merge({ archived: archived })
  end

  context 'with archived true' do
    let(:archived) { 'true' }

    it 'returns labels that are archived' do
      list_labels_with_archive
      expect(assigns(:labels)).to contain_exactly archived_label
    end
  end

  context 'with archived false' do
    let(:archived) { 'false' }

    it 'returns labels that are not archived' do
      list_labels_with_archive
      expect(assigns(:labels)).to match_array unarchived_labels
    end
  end

  context 'with archived not set' do
    let(:archived) { nil }

    it 'returns all labels' do
      list_labels_with_archive
      expect(assigns(:labels)).to match_array all_labels
    end
  end

  context 'with feature flag labels_archive disabled' do
    let(:archived) { true }

    before do
      stub_feature_flags(labels_archive: false)
    end

    it 'returns all labels' do
      list_labels_with_archive
      expect(assigns(:labels)).to match_array all_labels
    end
  end
end
