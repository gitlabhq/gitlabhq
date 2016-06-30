# Specifications for behavior common to all objects with executable attributes.
# It takes a `issuable_type`, and expect an `issuable`.

shared_examples 'issuable record that supports slash commands in its description and notes' do |issuable_type|
  let(:user) { create(:user) }
  let(:assignee) { create(:user, username: 'bob') }
  let(:project) { create(:project, :public) }
  let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }
  let!(:label_bug) { create(:label, project: project, title: 'bug') }
  let!(:label_feature) { create(:label, project: project, title: 'feature') }
  let(:new_url_opts) { {} }

  before do
    project.team << [user, :master]
    project.team << [assignee, :developer]
    login_with(user)
  end

  describe "new #{issuable_type}" do
    context 'with commands in the description' do
      it "creates the #{issuable_type} and interpret commands accordingly" do
        visit public_send("new_namespace_project_#{issuable_type}_path", project.namespace, project, new_url_opts)
        fill_in "#{issuable_type}_title", with: 'bug 345'
        fill_in "#{issuable_type}_description", with: "bug description\n/label ~bug\n/milestone %\"ASAP\""
        click_button "Submit #{issuable_type}".humanize

        issuable = project.public_send(issuable_type.to_s.pluralize).first

        expect(issuable.description).to eq "bug description\r\n"
        expect(issuable.labels).to eq [label_bug]
        expect(issuable.milestone).to eq milestone
        expect(page).to have_content 'bug 345'
        expect(page).to have_content 'bug description'
      end
    end
  end

  describe "note on #{issuable_type}" do
    before do
      visit public_send("namespace_project_#{issuable_type}_path", project.namespace, project, issuable)
    end

    context 'with a note containing commands' do
      it 'creates a note without the commands and interpret the commands accordingly' do
        page.within('.js-main-target-form') do
          fill_in 'note[note]', with: "Awesome!\n/assign @bob\n/label ~bug\n/milestone %\"ASAP\""
          click_button 'Comment'
        end

        expect(page).to have_content 'Awesome!'
        expect(page).not_to have_content '/assign @bob'
        expect(page).not_to have_content '/label ~bug'
        expect(page).not_to have_content '/milestone %"ASAP"'

        issuable.reload
        note = issuable.notes.user.first

        expect(note.note).to eq "Awesome!\r\n"
        expect(issuable.assignee).to eq assignee
        expect(issuable.labels).to eq [label_bug]
        expect(issuable.milestone).to eq milestone
      end
    end

    context 'with a note containing only commands' do
      it 'does not create a note but interpret the commands accordingly' do
        page.within('.js-main-target-form') do
          fill_in 'note[note]', with: "/assign @bob\n/label ~bug\n/milestone %\"ASAP\""
          click_button 'Comment'
        end

        expect(page).not_to have_content '/assign @bob'
        expect(page).not_to have_content '/label ~bug'
        expect(page).not_to have_content '/milestone %"ASAP"'
        expect(page).to have_content 'Your commands are being executed.'

        issuable.reload

        expect(issuable.notes.user).to be_empty
        expect(issuable.assignee).to eq assignee
        expect(issuable.labels).to eq [label_bug]
        expect(issuable.milestone).to eq milestone
      end
    end

    context "with a note marking the #{issuable_type} as todo" do
      it "creates a new todo for the #{issuable_type}" do
        page.within('.js-main-target-form') do
          fill_in 'note[note]', with: "/todo"
          click_button 'Comment'
        end

        expect(page).not_to have_content '/todo'
        expect(page).to have_content 'Your commands are being executed.'

        todos = TodosFinder.new(user).execute
        todo = todos.first

        expect(todos.size).to eq 1
        expect(todo).to be_pending
        expect(todo.target).to eq issuable
        expect(todo.author).to eq user
        expect(todo.user).to eq user
      end
    end

    context "with a note marking the #{issuable_type} as done" do
      before do
        TodoService.new.mark_todo(issuable, user)
      end

      it "creates a new todo for the #{issuable_type}" do
        todos = TodosFinder.new(user).execute
        todo = todos.first

        expect(todos.size).to eq 1
        expect(todos.first).to be_pending
        expect(todo.target).to eq issuable
        expect(todo.author).to eq user
        expect(todo.user).to eq user

        page.within('.js-main-target-form') do
          fill_in 'note[note]', with: "/done"
          click_button 'Comment'
        end

        expect(page).not_to have_content '/done'
        expect(page).to have_content 'Your commands are being executed.'

        expect(todo.reload).to be_done
      end
    end

    context "with a note subscribing to the #{issuable_type}" do
      it "creates a new todo for the #{issuable_type}" do
        expect(issuable.subscribed?(user)).to be_falsy

        page.within('.js-main-target-form') do
          fill_in 'note[note]', with: "/subscribe"
          click_button 'Comment'
        end

        expect(page).not_to have_content '/subscribe'
        expect(page).to have_content 'Your commands are being executed.'

        expect(issuable.subscribed?(user)).to be_truthy
      end
    end

    context "with a note unsubscribing to the #{issuable_type} as done" do
      before do
        issuable.subscribe(user)
      end

      it "creates a new todo for the #{issuable_type}" do
        expect(issuable.subscribed?(user)).to be_truthy

        page.within('.js-main-target-form') do
          fill_in 'note[note]', with: "/unsubscribe"
          click_button 'Comment'
        end

        expect(page).not_to have_content '/unsubscribe'
        expect(page).to have_content 'Your commands are being executed.'

        expect(issuable.subscribed?(user)).to be_falsy
      end
    end
  end
end
