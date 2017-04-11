import sqljs from 'sql.js';
import BalsamiqViewer from '~/blob/balsamiq/balsamiq_viewer';
import * as spinnerSrc from '~/spinner';
import ClassSpecHelper from '../../helpers/class_spec_helper';

describe('BalsamiqViewer', () => {
  let balsamiqViewer;
  let endpoint;
  let viewer;

  describe('class constructor', () => {
    beforeEach(() => {
      endpoint = 'endpoint';
      viewer = {
        dataset: {
          endpoint,
        },
      };

      spyOn(spinnerSrc, 'default');

      balsamiqViewer = new BalsamiqViewer(viewer);
    });

    it('should set .viewer', () => {
      expect(balsamiqViewer.viewer).toBe(viewer);
    });

    it('should set .endpoint', () => {
      expect(balsamiqViewer.endpoint).toBe(endpoint);
    });

    it('should instantiate Spinner', () => {
      expect(spinnerSrc.default).toHaveBeenCalledWith(viewer);
    });

    it('should set .spinner', () => {
      expect(balsamiqViewer.spinner).toEqual(jasmine.any(spinnerSrc.default));
    });
  });

  describe('loadFile', () => {
    let xhr;
    let spinner;

    beforeEach(() => {
      endpoint = 'endpoint';
      xhr = jasmine.createSpyObj('xhr', ['open', 'send']);
      spinner = jasmine.createSpyObj('spinner', ['start']);

      balsamiqViewer = jasmine.createSpyObj('balsamiqViewer', ['renderFile']);
      balsamiqViewer.endpoint = endpoint;
      balsamiqViewer.spinner = spinner;

      spyOn(window, 'XMLHttpRequest').and.returnValue(xhr);

      BalsamiqViewer.prototype.loadFile.call(balsamiqViewer);
    });

    it('should instantiate XMLHttpRequest', () => {
      expect(window.XMLHttpRequest).toHaveBeenCalled();
    });

    it('should call .open', () => {
      expect(xhr.open).toHaveBeenCalledWith('GET', endpoint, true);
    });

    it('should set .responseType', () => {
      expect(xhr.responseType).toBe('arraybuffer');
    });

    it('should set .onload', () => {
      expect(xhr.onload).toEqual(jasmine.any(Function));
    });

    it('should set .onerror', () => {
      expect(xhr.onerror).toBe(BalsamiqViewer.onError);
    });

    it('should call spinner.start', () => {
      expect(spinner.start).toHaveBeenCalled();
    });

    it('should call .send', () => {
      expect(xhr.send).toHaveBeenCalled();
    });
  });

  describe('renderFile', () => {
    let spinner;
    let container;
    let loadEvent;
    let previews;

    beforeEach(() => {
      loadEvent = { target: { response: {} } };
      viewer = jasmine.createSpyObj('viewer', ['appendChild']);
      spinner = jasmine.createSpyObj('spinner', ['stop']);
      previews = [0, 1, 2];

      balsamiqViewer = jasmine.createSpyObj('balsamiqViewer', ['initDatabase', 'getPreviews', 'renderPreview']);
      balsamiqViewer.viewer = viewer;
      balsamiqViewer.spinner = spinner;

      balsamiqViewer.getPreviews.and.returnValue(previews);
      balsamiqViewer.renderPreview.and.callFake(preview => preview);
      viewer.appendChild.and.callFake((containerElement) => {
        container = containerElement;
      });

      BalsamiqViewer.prototype.renderFile.call(balsamiqViewer, loadEvent);
    });

    it('should call spinner.stop', () => {
      expect(spinner.stop).toHaveBeenCalled();
    });

    it('should call .initDatabase', () => {
      expect(balsamiqViewer.initDatabase).toHaveBeenCalledWith(loadEvent.target.response);
    });

    it('should call .getPreviews', () => {
      expect(balsamiqViewer.getPreviews).toHaveBeenCalled();
    });

    it('should call .renderPreview for each preview', () => {
      const allArgs = balsamiqViewer.renderPreview.calls.allArgs();

      expect(allArgs.length).toBe(3);

      previews.forEach((preview, i) => {
        expect(allArgs[i][0]).toBe(preview);
      });
    });

    it('should set .innerHTML', () => {
      expect(container.innerHTML).toBe('012');
    });

    it('should add inline preview classes', () => {
      expect(container.classList[0]).toBe('list-inline');
      expect(container.classList[1]).toBe('previews');
    });

    it('should call viewer.appendChild', () => {
      expect(viewer.appendChild).toHaveBeenCalledWith(container);
    });
  });

  describe('initDatabase', () => {
    let database;
    let uint8Array;
    let data;

    beforeEach(() => {
      uint8Array = {};
      database = {};
      data = 'data';

      balsamiqViewer = {};

      spyOn(window, 'Uint8Array').and.returnValue(uint8Array);
      spyOn(sqljs, 'Database').and.returnValue(database);

      BalsamiqViewer.prototype.initDatabase.call(balsamiqViewer, data);
    });

    it('should instantiate Uint8Array', () => {
      expect(window.Uint8Array).toHaveBeenCalledWith(data);
    });

    it('should call sqljs.Database', () => {
      expect(sqljs.Database).toHaveBeenCalledWith(uint8Array);
    });

    it('should set .database', () => {
      expect(balsamiqViewer.database).toBe(database);
    });
  });

  describe('getPreviews', () => {
    let database;
    let thumbnails;
    let getPreviews;

    beforeEach(() => {
      database = jasmine.createSpyObj('database', ['exec']);
      thumbnails = [{ values: [0, 1, 2] }];

      balsamiqViewer = {
        database,
      };

      spyOn(BalsamiqViewer, 'parsePreview').and.callFake(preview => preview.toString());
      database.exec.and.returnValue(thumbnails);

      getPreviews = BalsamiqViewer.prototype.getPreviews.call(balsamiqViewer);
    });

    it('should call database.exec', () => {
      expect(database.exec).toHaveBeenCalledWith('SELECT * FROM thumbnails');
    });

    it('should call .parsePreview for each value', () => {
      const allArgs = BalsamiqViewer.parsePreview.calls.allArgs();

      expect(allArgs.length).toBe(3);

      thumbnails[0].values.forEach((value, i) => {
        expect(allArgs[i][0]).toBe(value);
      });
    });

    it('should return an array of parsed values', () => {
      expect(getPreviews).toEqual(['0', '1', '2']);
    });
  });

  describe('getTitle', () => {
    let database;
    let resourceID;
    let resource;
    let getTitle;

    beforeEach(() => {
      database = jasmine.createSpyObj('database', ['exec']);
      resourceID = 4;
      resource = 'resource';

      balsamiqViewer = {
        database,
      };

      database.exec.and.returnValue(resource);

      getTitle = BalsamiqViewer.prototype.getTitle.call(balsamiqViewer, resourceID);
    });

    it('should call database.exec', () => {
      expect(database.exec).toHaveBeenCalledWith(`SELECT * FROM resources WHERE id = '${resourceID}'`);
    });

    it('should return the selected resource', () => {
      expect(getTitle).toBe(resource);
    });
  });

  describe('renderPreview', () => {
    let previewElement;
    let innerHTML;
    let preview;
    let renderPreview;

    beforeEach(() => {
      innerHTML = '<a>innerHTML</a>';
      previewElement = {
        outerHTML: '<p>outerHTML</p>',
        classList: jasmine.createSpyObj('classList', ['add']),
      };
      preview = {};

      balsamiqViewer = jasmine.createSpyObj('balsamiqViewer', ['renderTemplate']);

      spyOn(document, 'createElement').and.returnValue(previewElement);
      balsamiqViewer.renderTemplate.and.returnValue(innerHTML);

      renderPreview = BalsamiqViewer.prototype.renderPreview.call(balsamiqViewer, preview);
    });

    it('should call document.createElement', () => {
      expect(document.createElement).toHaveBeenCalledWith('li');
    });

    it('should call classList.add', () => {
      expect(previewElement.classList.add).toHaveBeenCalledWith('preview');
    });

    it('should call .renderTemplate', () => {
      expect(balsamiqViewer.renderTemplate).toHaveBeenCalledWith(preview);
    });

    it('should set .innerHTML', () => {
      expect(previewElement.innerHTML).toBe(innerHTML);
    });

    it('should return .outerHTML', () => {
      expect(renderPreview).toBe(previewElement.outerHTML);
    });
  });

  describe('renderTemplate', () => {
    let preview;
    let name;
    let title;
    let template;
    let renderTemplate;

    beforeEach(() => {
      preview = { resourceID: 1, image: 'image' };
      name = 'name';
      title = 'title';
      template = `
        <div class="panel panel-default">
          <div class="panel-heading">name</div>
          <div class="panel-body">
            <img class="img-thumbnail" src="data:image/png;base64,image"/>
          </div>
        </div>
      `;

      balsamiqViewer = jasmine.createSpyObj('balsamiqViewer', ['getTitle']);

      spyOn(BalsamiqViewer, 'parseTitle').and.returnValue(name);
      spyOn(BalsamiqViewer, 'PREVIEW_TEMPLATE').and.returnValue(template);
      balsamiqViewer.getTitle.and.returnValue(title);

      renderTemplate = BalsamiqViewer.prototype.renderTemplate.call(balsamiqViewer, preview);
    });

    it('should call .getTitle', () => {
      expect(balsamiqViewer.getTitle).toHaveBeenCalledWith(preview.resourceID);
    });

    it('should call .parseTitle', () => {
      expect(BalsamiqViewer.parseTitle).toHaveBeenCalledWith(title);
    });

    it('should call .PREVIEW_TEMPLATE', () => {
      expect(BalsamiqViewer.PREVIEW_TEMPLATE).toHaveBeenCalledWith({
        name,
        image: preview.image,
      });
    });

    it('should return the template string', function () {
      expect(renderTemplate.trim()).toBe(template.trim());
    });
  });

  describe('parsePreview', () => {
    let preview;
    let parsePreview;

    beforeEach(() => {
      preview = ['{}', '{ "id": 1 }'];

      spyOn(JSON, 'parse').and.callThrough();

      parsePreview = BalsamiqViewer.parsePreview(preview);
    });

    ClassSpecHelper.itShouldBeAStaticMethod(BalsamiqViewer, 'parsePreview');

    it('should call JSON.parse', () => {
      expect(JSON.parse).toHaveBeenCalledWith(preview[1]);
    });

    it('should return the parsed JSON', () => {
      expect(parsePreview).toEqual(JSON.parse('{ "id": 1 }'));
    });
  });

  describe('parseTitle', () => {
    let title;
    let parseTitle;

    beforeEach(() => {
      title = [{ values: [['{}', '{}', '{"name":"name"}']] }];

      spyOn(JSON, 'parse').and.callThrough();

      parseTitle = BalsamiqViewer.parseTitle(title);
    });

    ClassSpecHelper.itShouldBeAStaticMethod(BalsamiqViewer, 'parsePreview');

    it('should call JSON.parse', () => {
      expect(JSON.parse).toHaveBeenCalledWith(title[0].values[0][2]);
    });

    it('should return the name value', () => {
      expect(parseTitle).toBe('name');
    });
  });

  describe('onError', () => {
    let onError;

    beforeEach(() => {
      spyOn(window, 'Flash');

      onError = BalsamiqViewer.onError();
    });

    ClassSpecHelper.itShouldBeAStaticMethod(BalsamiqViewer, 'onError');

    it('should instantiate Flash', () => {
      expect(window.Flash).toHaveBeenCalledWith('Balsamiq file could not be loaded.');
    });

    it('should return Flash', () => {
      expect(onError).toEqual(jasmine.any(window.Flash));
    });
  });
});
