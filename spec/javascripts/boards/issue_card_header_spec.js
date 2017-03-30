import Vue from 'vue';
import headerComponent from '~/boards/components/issue_card_header';

const propData = {
  confidential: true,
  title: 'this is a title',
  issueId: 23,
  assignee: {
    username: 'batman',
    name: 'Bruce Wayne',
    avatar: 'https://batman.gravatar',
  },
  issueLinkBase: 'linkBase',
  rootPath: 'rootPath',
};

const createComponent = (propsData) => {
  const Component = Vue.extend(headerComponent);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

describe('IssueCardHeader', () => {
  describe('props', () => {
    const props = headerComponent.props;

    it('should have confidential prop', () => {
      const { confidential } = props;
      const ConfidentialClass = confidential.type;

      expect(confidential).toBeDefined();
      expect(new ConfidentialClass() instanceof Boolean).toBeTruthy();
      expect(confidential.required).toBeTruthy();
    });

    it('should have title prop', () => {
      const { title } = props;
      const TitleClass = title.type;

      expect(title).toBeDefined();
      expect(new TitleClass() instanceof String).toBeTruthy();
      expect(title.required).toBeTruthy();
    });

    it('should have issueId prop', () => {
      const { issueId } = props;
      const IssueIdClass = issueId.type;

      expect(issueId).toBeDefined();
      expect(new IssueIdClass() instanceof Number).toBeTruthy();
      expect(issueId.required).toBeTruthy();
    });

    it('should have assignee prop', () => {
      const { assignee } = props;

      expect(assignee).toBeDefined();
      expect(assignee instanceof Object).toBeTruthy();
      expect(assignee.required).toBeTruthy();
    });

    it('should have issueLinkBase prop', () => {
      const { issueLinkBase } = props;
      const IssueLinkBaseClass = issueLinkBase.type;

      expect(issueLinkBase).toBeDefined();
      expect(new IssueLinkBaseClass() instanceof String).toBeTruthy();
      expect(issueLinkBase.required).toBeTruthy();
    });

    it('should have rootPath prop', () => {
      const { rootPath } = props;
      const RootPathClass = rootPath.type;

      expect(rootPath).toBeDefined();
      expect(new RootPathClass() instanceof String).toBeTruthy();
      expect(rootPath.required).toBeTruthy();
    });
  });

  describe('computed', () => {
    describe('hasAssignee', () => {
      it('should return whether there is an assignee', () => {
        const data = Object.assign({}, propData);

        let vm = createComponent(data);
        expect(vm.hasAssignee).toEqual(true);

        data.assignee = {};
        vm = createComponent(data);
        expect(vm.hasAssignee).toEqual(false);
      });
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const el = createComponent(propData).$el;
      expect(el.tagName).toEqual('DIV');
      expect(el.classList.contains('card-header')).toEqual(true);

      const confidentialIcon = el.querySelector('.confidential-icon');
      expect(confidentialIcon.tagName).toEqual('I');
      expect(confidentialIcon.classList.contains('fa')).toEqual(true);
      expect(confidentialIcon.classList.contains('fa-eye-slash')).toEqual(true);

      const cardTitle = el.querySelector('.card-title');
      expect(cardTitle.tagName).toEqual('H4');

      const cardTitleLink = cardTitle.querySelector('a');
      expect(cardTitleLink.getAttribute('href')).toEqual(`${propData.issueLinkBase}/${propData.issueId}`);
      expect(cardTitleLink.getAttribute('title')).toEqual(propData.title);
      expect(cardTitleLink.innerText).toEqual(propData.title);

      const cardNumber = cardTitle.querySelector('.card-number');
      expect(cardNumber.tagName).toEqual('SPAN');
      expect(cardNumber.innerText).toEqual(`#${propData.issueId}`);

      const cardAssignee = el.querySelector('.card-assignee');
      expect(cardAssignee.tagName).toEqual('A');
      expect(cardAssignee.getAttribute('href')).toEqual(`${propData.rootPath}${propData.assignee.username}`);
      expect(cardAssignee.getAttribute('title')).toEqual(`Assigned to ${propData.assignee.name}`);

      const cardAssigneeImage = cardAssignee.querySelector('img');
      expect(cardAssigneeImage.getAttribute('src')).toEqual(propData.assignee.avatar);
      expect(cardAssigneeImage.getAttribute('alt')).toEqual(`Avatar for ${propData.assignee.name}`);
    });

    it('should not display confidential icon if confidential is false', () => {
      const data = Object.assign({}, propData);
      data.confidential = false;
      const el = createComponent(data).$el;

      expect(el.querySelector('.confidential-icon')).toEqual(null);
    });

    it('should not render assignee if there is no assignee', () => {
      const data = Object.assign({}, propData);
      data.assignee = {};
      const el = createComponent(data).$el;

      expect(el.querySelector('.card-assignee')).toEqual(null);
    });
  });
});
