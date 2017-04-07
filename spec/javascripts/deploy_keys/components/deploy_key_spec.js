import Vue from 'vue';
import deployKeyComponent from '~/deploy_keys/components/deploy_key';

fdescribe('DeployKey', () => {
  const propsData = {
    id: 1,
    title: 'title',
    fingerprint: '49:43:d7:89:63:be:0a:d6:a2:93:fc:86:59:2e:36:4d',
    projects: [{
      full_path: 'full_path',
      full_name: 'full_name',
    }],
    path: 'path',
    createdAt: new Date().toISOString(),
  };
  let DeployKeyComponent;

  beforeEach(() => {
    DeployKeyComponent = Vue.extend(deployKeyComponent);
  });

  it('should not render "Write access allowed" by default', () => {
    const component = new DeployKeyComponent({
      propsData,
    }).$mount();

    const el = component.$el;
    expect(el.querySelector('.write-access-allowed')).toBeNull();
  });

  it('should render "Write access allowed" when canPush is true', () => {
    const newPropsData = Object.assign({}, propsData);
    newPropsData.canPush = true;

    const component = new DeployKeyComponent({
      propsData: newPropsData,
    }).$mount();

    const el = component.$el;
    expect(el.querySelector('.write-access-allowed')).not.toBeNull();
  });

  it('should render created date using timeago', () => {
    const component = new DeployKeyComponent({
      propsData,
    }).$mount();

    const el = component.$el;
    const timeagoElText = el.querySelector('.key-created-at span').textContent.trim();
    const timeago = gl.utils.getTimeago().format(propsData.createdAt, 'gl_en')

    expect(timeagoElText).toEqual(timeago);
  });

  it('should render created date tooltip title', () => {
    const component = new DeployKeyComponent({
      propsData,
    }).$mount();

    const el = component.$el;
    const timeagoEl = el.querySelector('.key-created-at span');
    const formattedTitle = gl.utils.formatDate(new Date(propsData.createdAt));

    expect(timeagoEl.dataset.originalTitle).toEqual(formattedTitle);
  });

  describe('confirmationMesssage', () => {
    it('should set data attribute when enable is false and canRemove is true', () => {
      const newPropsData = Object.assign({}, propsData);
      newPropsData.enable = false;
      newPropsData.canRemove = true;

      const component = new DeployKeyComponent({
        propsData: newPropsData,
      }).$mount();

      const el = component.$el;
      const actionLink = el.querySelector('a.btn');
      expect(actionLink.dataset.confirm).toEqual('You are going to remove deploy key. Are you sure?');
    });

    it('should not set data attribute when enable is true and canRemove is false', () => {
      const component = new DeployKeyComponent({
        propsData,
      }).$mount();

      const el = component.$el;
      const actionLink = el.querySelector('a.btn');
      expect(actionLink.dataset.confirm).toEqual('');
    });

    it('should not set data attribute when enable is true canRemove is true', () => {
      const newPropsData = Object.assign({}, propsData);
      newPropsData.canRemove = true;

      const component = new DeployKeyComponent({
        propsData: newPropsData,
      }).$mount();

      const el = component.$el;
      const actionLink = el.querySelector('a.btn');
      expect(actionLink.dataset.confirm).toEqual('');
    });

    it('should not set data attribute when enable is false and canRemove is false', () => {
      const newPropsData = Object.assign({}, propsData);
      newPropsData.enable = false;

      const component = new DeployKeyComponent({
        propsData: newPropsData,
      }).$mount();

      const el = component.$el;
      const actionLink = el.querySelector('a.btn');
      expect(actionLink.dataset.confirm).toEqual('');
    });
  });

  describe('href', () => {
    it('should render path with /enable when enable is true', () => {
      const component = new DeployKeyComponent({
        propsData,
      }).$mount();

      const el = component.$el;
      const href = el.querySelector('a.btn').getAttribute('href');
      const lastIndex = href.lastIndexOf('/enable');
      expect(lastIndex).toEqual(href.length - '/enable'.length);
    });

    it('should render path with /disable when enable is false', () => {
      const newPropsData = Object.assign({}, propsData);
      newPropsData.enable = false;

      const component = new DeployKeyComponent({
        propsData: newPropsData,
      }).$mount();

      const el = component.$el;
      const href = el.querySelector('a.btn').getAttribute('href');
      const lastIndex = href.lastIndexOf('/disable');
      expect(lastIndex).toEqual(href.length - '/disable'.length);
    });
  });

  describe('linkText', () => {
    it('should render "Enable" when enable is true', () => {
      const component = new DeployKeyComponent({
        propsData,
      }).$mount();

      const el = component.$el;

      const linkText = el.querySelector('a.btn').textContent.trim();
      expect(linkText).toEqual('Enable');
    });

    it('should render "Remove" when enable is false and canRemove is true', () => {
      const newPropsData = Object.assign({}, propsData);
      newPropsData.enable = false;
      newPropsData.canRemove = true;

      const component = new DeployKeyComponent({
        propsData: newPropsData,
      }).$mount();

      const el = component.$el;

      const linkText = el.querySelector('a.btn').textContent.trim();
      expect(linkText).toEqual('Remove');
    });

    it('should render "Disable" when enable and canRemove are false', () => {
      const newPropsData = Object.assign({}, propsData);
      newPropsData.enable = false;

      const component = new DeployKeyComponent({
        propsData: newPropsData,
      }).$mount();

      const el = component.$el;

      const linkText = el.querySelector('a.btn').textContent.trim();
      expect(linkText).toEqual('Disable');
    });
  });
});
