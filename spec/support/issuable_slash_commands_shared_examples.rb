# Specifications for behavior common to all objects with executable attributes.
# It takes a `issuable_type`, and expect an `issuable`.

shared_examples 'issuable record that supports slash commands in its description and notes' do |issuable_type|
  include SlashCommandsHelpers
  include WaitForAjax

  let(:master) { create(:user) }
  let(:assignee) { create(:user, username: 'bob') }
  let(:guest) { create(:user) }
  let(:project) { create(:project, :public) }
  let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }
  let!(:label_bug) { create(:label, project: project, title: 'bug') }
  let!(:label_feature) { create(:label, project: project, title: 'feature') }
  let(:new_url_opts) { {} }

  before do
    project.team << [master, :master]
    project.team << [assignee, :developer]
    project.team << [guest, :guest]
    login_with(master)
  end

  after do
    # Ensure all outstanding Ajax requests are complete to avoid database deadlocks
    wait_for_ajax
  end

  describe "new #{issuable_type}" do
    context 'with commands in the description' do
      it "creates the #{issuable_type} and interpret commands accordingly" do
        visit public_send("new_namespace_project_#{issuable_type}_path", project.namespace, project, new_url_opts)
        fill_in "#{issuable_type}_title", with: 'bug 345'
        fill_in "#{issuable_type}_description", with: "bug description\n/label ~bug\n/milestone %\"ASAP\""
        click_button "Submit #{issuable_type}".humanize

        issuable = project.public_send(issuable_type.to_s.pluralize).first

        expect(issuable.description).to eq "bug description"
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
        write_note("Awesome!\n/assign @bob\n/label ~bug\n/milestone %\"ASAP\"")

        expect(page).to have_content 'Awesome!'
        expect(page).not_to have_content '/assign @bob'
        expect(page).not_to have_content '/label ~bug'
        expect(page).not_to have_content '/milestone %"ASAP"'

        issuable.reload
        note = issuable.notes.user.first

        expect(note.note).to eq "Awesome!"
        expect(issuable.assignee).to eq assignee
        expect(issuable.labels).to eq [label_bug]
        expect(issuable.milestone).to eq milestone
      end
    end

    context 'with a note containing only commands' do
      it 'does not create a note but interpret the commands accordingly' do
        write_note("/assign @bob\n/label ~bug\n/milestone %\"ASAP\"")

        expect(page).not_to have_content '/assign @bob'
        expect(page).not_to have_content '/label ~bug'
        expect(page).not_to have_content '/milestone %"ASAP"'
        expect(page).to have_content 'Your commands have been executed!'

        issuable.reload

        expect(issuable.notes.user).to be_empty
        expect(issuable.assignee).to eq assignee
        expect(issuable.labels).to eq [label_bug]
        expect(issuable.milestone).to eq milestone
      end
    end

    context "with a note closing the #{issuable_type}" do
      before do
        expect(issuable).to be_open
      end

      context "when current user can close #{issuable_type}" do
        it "closes the #{issuable_type}" do
          write_note("/close")

          expect(page).not_to have_content '/close'
          expect(page).to have_content 'Your commands have been executed!'

          expect(issuable.reload).to be_closed
        end
      end

      context "when current user cannot close #{issuable_type}" do
        before do
          logout
          login_with(guest)
          visit public_send("namespace_project_#{issuable_type}_path", project.namespace, project, issuable)
        end

        it "does not close the #{issuable_type}" do
          write_note("/close")

          expect(page).not_to have_content '/close'
          expect(page).not_to have_content 'Your commands have been executed!'

          expect(issuable).to be_open
        end
      end
    end

    context "with a note reopening the #{issuable_type}" do
      before do
        issuable.close
        expect(issuable).to be_closed
      end

      context "when current user can reopen #{issuable_type}" do
        it "reopens the #{issuable_type}" do
          write_note("/reopen")

          expect(page).not_to have_content '/reopen'
          expect(page).to have_content 'Your commands have been executed!'

          expect(issuable.reload).to be_open
        end
      end

      context "when current user cannot reopen #{issuable_type}" do
        before do
          logout
          login_with(guest)
          visit public_send("namespace_project_#{issuable_type}_path", project.namespace, project, issuable)
        end

        it "does not reopen the #{issuable_type}" do
          write_note("/reopen")

          expect(page).not_to have_content '/reopen'
          expect(page).not_to have_content 'Your commands have been executed!'

          expect(issuable).to be_closed
        end
      end
    end

    context "with a note changing the #{issuable_type}'s title" do
      context "when current user can change title of #{issuable_type}" do
        it "reopens the #{issuable_type}" do
          write_note("/title Awesome new title")

          expect(page).not_to have_content '/title'
          expect(page).to have_content 'Your commands have been executed!'

          expect(issuable.reload.title).to eq 'Awesome new title'
        end
      end

      context "when current user cannot change title of #{issuable_type}" do
        before do
          logout
          login_with(guest)
          visit public_send("namespace_project_#{issuable_type}_path", project.namespace, project, issuable)
        end

        it "does not reopen the #{issuable_type}" do
          write_note("/title Awesome new title")

          expect(page).not_to have_content '/title'
          expect(page).not_to have_content 'Your commands have been executed!'

          expect(issuable.reload.title).not_to eq 'Awesome new title'
        end
      end
    end

    context "with a note marking the #{issuable_type} as todo" do
      it "creates a new todo for the #{issuable_type}" do
        write_note("/todo")

        expect(page).not_to have_content '/todo'
        expect(page).to have_content 'Your commands have been executed!'

        todos = TodosFinder.new(master).execute
        todo = todos.first

        expect(todos.size).to eq 1
        expect(todo).to be_pending
        expect(todo.target).to eq issuable
        expect(todo.author).to eq master
        expect(todo.user).to eq master
      end
    end

    context "with a note marking the #{issuable_type} as done" do
      before do
        TodoService.new.mark_todo(issuable, master)
      end

      it "creates a new todo for the #{issuable_type}" do
        todos = TodosFinder.new(master).execute
        todo = todos.first

        expect(todos.size).to eq 1
        expect(todos.first).to be_pending
        expect(todo.target).to eq issuable
        expect(todo.author).to eq master
        expect(todo.user).to eq master

        write_note("/done")

        expect(page).not_to have_content '/done'
        expect(page).to have_content 'Your commands have been executed!'

        expect(todo.reload).to be_done
      end
    end

    context "with a note subscribing to the #{issuable_type}" do
      it "creates a new todo for the #{issuable_type}" do
        expect(issuable.subscribed?(master)).to be_falsy

        write_note("/subscribe")

        expect(page).not_to have_content '/subscribe'
        expect(page).to have_content 'Your commands have been executed!'

        expect(issuable.subscribed?(master)).to be_truthy
      end
    end

    context "with a note unsubscribing to the #{issuable_type} as done" do
      before do
        issuable.subscribe(master)
      end

      it "creates a new todo for the #{issuable_type}" do
        expect(issuable.subscribed?(master)).to be_truthy

        write_note("/unsubscribe")

        expect(page).not_to have_content '/unsubscribe'
        expect(page).to have_content 'Your commands have been executed!'

        expect(issuable.subscribed?(master)).to be_falsy
      end
    end
  end
end
