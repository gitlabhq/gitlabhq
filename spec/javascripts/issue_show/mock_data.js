export default {
  initialRequest: {
    title: '<p>this is a title</p>',
    title_text: 'this is a title',
    description: '<p>this is a description!</p>',
    description_text: 'this is a description',
    task_status: '2 of 4 completed',
    updated_at: new Date().toString(),
  },
  secondRequest: {
    title: '<p>2</p>',
    title_text: '2',
    description: '<p>42</p>',
    description_text: '42',
    task_status: '0 of 0 completed',
    updated_at: new Date().toString(),
  },
  issueSpecRequest: {
    title: '<p>this is a title</p>',
    title_text: 'this is a title',
    description: '<li class="task-list-item enabled"><input type="checkbox" class="task-list-item-checkbox">Task List Item</li>',
    description_text: '- [ ] Task List Item',
    task_status: '0 of 1 completed',
    updated_at: new Date().toString(),
  },
};
