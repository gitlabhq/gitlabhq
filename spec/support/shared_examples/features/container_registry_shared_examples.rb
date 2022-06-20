# frozen_string_literal: true

RSpec.shared_examples 'handling feature network errors with the container registry' do
  it 'displays the error message' do
    visit_container_registry

    expect(page).to have_content 'We are having trouble connecting to the Container Registry'
  end
end

RSpec.shared_examples 'rejecting tags destruction for an importing repository on' do |tags: []|
  it 'rejects the tag destruction operation' do
    service = instance_double('Projects::ContainerRepository::DeleteTagsService')
    expect(service).to receive(:execute).with(container_repository) { { status: :error, message: 'repository importing' } }
    expect(Projects::ContainerRepository::DeleteTagsService).to receive(:new).with(container_repository.project, user, tags: tags) { service }

    first('[data-testid="additional-actions"]').click
    first('[data-testid="single-delete-button"]').click
    expect(find('.modal .modal-title')).to have_content _('Remove tag')
    find('.modal .modal-footer .btn-danger').click

    expect(page).to have_content('Tags temporarily cannot be marked for deletion. Please try again in a few minutes.')
    expect(page).to have_link('More details', href: help_page_path('user/packages/container_registry/index', anchor: 'tags-temporarily-cannot-be-marked-for-deletion'))
  end
end
