import sqljs from 'sql.js';
import axios from '~/lib/utils/axios_utils';
import BalsamiqViewer from '~/blob/balsamiq/balsamiq_viewer';
import ClassSpecHelper from '../../helpers/class_spec_helper';

describe('BalsamiqViewer', () => {
  const mockArrayBuffer = new ArrayBuffer(10);
  let balsamiqViewer;
  let viewer;

  describe('class constructor', () => {
    beforeEach(() => {
      viewer = {};

      balsamiqViewer = new BalsamiqViewer(viewer);
    });

    it('should set .viewer', () => {
      expect(balsamiqViewer.viewer).toBe(viewer);
    });
  });

  describe('loadFile', () => {
    let bv;
    const endpoint = 'endpoint';
    const requestSuccess = Promise.resolve({
      data: mockArrayBuffer,
      status: 200,
    });

    beforeEach(() => {
      viewer = {};
      bv = new BalsamiqViewer(viewer);
    });

    it('should call `axios.get` on `endpoint` param with responseType set to `arraybuffer', () => {
      spyOn(axios, 'get').and.returnValue(requestSuccess);
      spyOn(bv, 'renderFile').and.stub();

      bv.loadFile(endpoint);

      expect(axios.get).toHaveBeenCalledWith(
        endpoint,
        jasmine.objectContaining({
          responseType: 'arraybuffer',
        }),
      );
    });

    it('should call `renderFile` on request success', done => {
      spyOn(axios, 'get').and.returnValue(requestSuccess);
      spyOn(bv, 'renderFile').and.callFake(() => {});

      bv.loadFile(endpoint)
        .then(() => {
          expect(bv.renderFile).toHaveBeenCalledWith(mockArrayBuffer);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should not call `renderFile` on request failure', done => {
      spyOn(axios, 'get').and.returnValue(Promise.reject());
      spyOn(bv, 'renderFile');

      bv.loadFile(endpoint)
        .then(() => {
          done.fail('Expected loadFile to throw error!');
        })
        .catch(() => {
          expect(bv.renderFile).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('renderFile', () => {
    let container;
    let previews;

    beforeEach(() => {
      viewer = jasmine.createSpyObj('viewer', ['appendChild']);
      previews = [document.createElement('ul'), document.createElement('ul')];

      balsamiqViewer = jasmine.createSpyObj('balsamiqViewer', [
        'initDatabase',
        'getPreviews',
        'renderPreview',
      ]);
      balsamiqViewer.viewer = viewer;

      balsamiqViewer.getPreviews.and.returnValue(previews);
      balsamiqViewer.renderPreview.and.callFake(preview => preview);
      viewer.appendChild.and.callFake(containerElement => {
        container = containerElement;
      });

      BalsamiqViewer.prototype.renderFile.call(balsamiqViewer, mockArrayBuffer);
    });

    it('should call .initDatabase', () => {
      expect(balsamiqViewer.initDatabase).toHaveBeenCalledWith(mockArrayBuffer);
    });

    it('should call .getPreviews', () => {
      expect(balsamiqViewer.getPreviews).toHaveBeenCalled();
    });

    it('should call .renderPreview for each preview', () => {
      const allArgs = balsamiqViewer.renderPreview.calls.allArgs();

      expect(allArgs.length).toBe(2);

      previews.forEach((preview, i) => {
        expect(allArgs[i][0]).toBe(preview);
      });
    });

    it('should set the container HTML', () => {
      expect(container.innerHTML).toBe('<ul></ul><ul></ul>');
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

  describe('getResource', () => {
    let database;
    let resourceID;
    let resource;
    let getResource;

    beforeEach(() => {
      database = jasmine.createSpyObj('database', ['exec']);
      resourceID = 4;
      resource = ['resource'];

      balsamiqViewer = {
        database,
      };

      database.exec.and.returnValue(resource);

      getResource = BalsamiqViewer.prototype.getResource.call(balsamiqViewer, resourceID);
    });

    it('should call database.exec', () => {
      expect(database.exec).toHaveBeenCalledWith(
        `SELECT * FROM resources WHERE id = '${resourceID}'`,
      );
    });

    it('should return the selected resource', () => {
      expect(getResource).toBe(resource[0]);
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

    it('should call classList.add', () => {
      expect(previewElement.classList.add).toHaveBeenCalledWith('preview');
    });

    it('should call .renderTemplate', () => {
      expect(balsamiqViewer.renderTemplate).toHaveBeenCalledWith(preview);
    });

    it('should set .innerHTML', () => {
      expect(previewElement.innerHTML).toBe(innerHTML);
    });

    it('should return element', () => {
      expect(renderPreview).toBe(previewElement);
    });
  });

  describe('renderTemplate', () => {
    let preview;
    let name;
    let resource;
    let template;
    let renderTemplate;

    beforeEach(() => {
      preview = { resourceID: 1, image: 'image' };
      name = 'name';
      resource = 'resource';
      template = `
        <div class="card">
          <div class="card-header">name</div>
          <div class="card-body">
            <img class="img-thumbnail" src="data:image/png;base64,image"/>
          </div>
        </div>
      `;

      balsamiqViewer = jasmine.createSpyObj('balsamiqViewer', ['getResource']);

      spyOn(BalsamiqViewer, 'parseTitle').and.returnValue(name);
      balsamiqViewer.getResource.and.returnValue(resource);

      renderTemplate = BalsamiqViewer.prototype.renderTemplate.call(balsamiqViewer, preview);
    });

    it('should call .getResource', () => {
      expect(balsamiqViewer.getResource).toHaveBeenCalledWith(preview.resourceID);
    });

    it('should call .parseTitle', () => {
      expect(BalsamiqViewer.parseTitle).toHaveBeenCalledWith(resource);
    });

    it('should return the template string', function() {
      expect(renderTemplate.replace(/\s/g, '')).toEqual(template.replace(/\s/g, ''));
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

    it('should return the parsed JSON', () => {
      expect(parsePreview).toEqual(JSON.parse('{ "id": 1 }'));
    });
  });

  describe('parseTitle', () => {
    let title;
    let parseTitle;

    beforeEach(() => {
      title = { values: [['{}', '{}', '{"name":"name"}']] };

      spyOn(JSON, 'parse').and.callThrough();

      parseTitle = BalsamiqViewer.parseTitle(title);
    });

    ClassSpecHelper.itShouldBeAStaticMethod(BalsamiqViewer, 'parsePreview');

    it('should return the name value', () => {
      expect(parseTitle).toBe('name');
    });
  });
});
