import Vue from 'vue';
import IntervalPatternInput from '~/pipeline_schedules/components/interval_pattern_input';

const IntervalPatternInputComponent = Vue.extend(IntervalPatternInput);

const dataDefaults = {
  inputNameAttribute: 'schedule[cron]',
  cronSyntaxUrl: 'https://en.wikipedia.org/wiki/Cron',
  customInputEnabled: false,
};

const cronIntervalPresets = {
  everyDay: '0 4 * * *',
  everyWeek: '0 4 * * 0',
  everyMonth: '0 4 1 * *',
};

describe('Interval Pattern Input Component', () => {
  describe('when prop initialCronInterval is passed (edit)', () => {
    describe('when prop initialCronInterval is custom', () => {
      beforeEach(() => {
        this.initialCronInterval = '1 2 3 4 5';
        this.intervalPatternComponent = new IntervalPatternInputComponent({
          propsData: {
            initialCronInterval: this.initialCronInterval,
          },
        }).$mount();
      });

      it('is initialized as a Vue component', () => {
        expect(this.intervalPatternComponent).toBeDefined();
      });

      it('prop initialCronInterval is set', () => {
        expect(this.intervalPatternComponent.initialCronInterval).toBe(this.initialCronInterval);
      });

      it('sets showUnsetWarning to false', (done) => {
        Vue.nextTick(() => {
          expect(this.intervalPatternComponent.showUnsetWarning).toBe(false);
          done();
        });
      });

      it('does not render showUnsetWarning', (done) => {
        Vue.nextTick(() => {
          expect(this.intervalPatternComponent.$el.outerHTML).not.toContain('Schedule not yet set');
          done();
        });
      });

      it('sets isEditable to true', (done) => {
        Vue.nextTick(() => {
          expect(this.intervalPatternComponent.isEditable).toBe(true);
          done();
        });
      });
    });

    describe('when prop initialCronInterval is preset', () => {
      beforeEach(() => {
        this.intervalPatternComponent = new IntervalPatternInputComponent({
          propsData: {
            inputNameAttribute: cronInputName,
            initialCronInterval: '0 4 * * *',
          },
        }).$mount();
      });

      it('is initialized as a Vue component', () => {
        expect(this.intervalPatternComponent).toBeDefined();
      });

      it('sets showUnsetWarning to false', (done) => {
        Vue.nextTick(() => {
          expect(this.intervalPatternComponent.showUnsetWarning).toBe(false);
          done();
        });
      });

      it('does not render showUnsetWarning', (done) => {
        Vue.nextTick(() => {
          expect(this.intervalPatternComponent.$el.outerHTML).not.toContain('Schedule not yet set');
          done();
        });
      });

      it('sets isEditable to false', (done) => {
        Vue.nextTick(() => {
          expect(this.intervalPatternComponent.isEditable).toBe(false);
          done();
        });
      });
    });

    _.each(dataDefaults, (val, key) => {
      it(`data default ${key} is properly set`, () => {
        expect(this.intervalPatternComponent[key]).toBe(val);
      });
    });

    _.each(cronIntervalPresets, (val, key) => {
      it(`cronIntervalPresets ${key} is properly set`, () => {
        expect(this.intervalPatternComponent.cronIntervalPresets[key]).toBe(val);
      });
    });
  });

  describe('when prop initialCronInterval is not passed (new)', () => {
    beforeEach(() => {
      this.intervalPatternComponent = new IntervalPatternInputComponent({
        propsData: {
          inputNameAttribute: cronInputName,
        },
      }).$mount();
    });

    it('is initialized as a Vue component', () => {
      expect(this.intervalPatternComponent).toBeDefined();
    });

    it('prop initialCronInterval is set', () => {
      const defaultInitialCronInterval = '';
      expect(this.intervalPatternComponent.initialCronInterval).toBe(defaultInitialCronInterval);
    });

    it('sets showUnsetWarning to true', (done) => {
      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.showUnsetWarning).toBe(true);
        done();
      });
    });

    it('renders showUnsetWarning to true', (done) => {
      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.$el.outerHTML).toContain('Schedule not yet set');
        done();
      });
    });

    it('sets isEditable to true', (done) => {
      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.isEditable).toBe(true);
        done();
      });
    });

    _.each(dataDefaults, (val, key) => {
      it(`data default ${key} is properly set`, () => {
        expect(this.intervalPatternComponent[key]).toBe(val);
      });
    });

    _.each(cronIntervalPresets, (val, key) => {
      it(`cronIntervalPresets ${key} is properly set`, () => {
        expect(this.intervalPatternComponent.cronIntervalPresets[key]).toBe(val);
      });
    });
  });

  describe('User Actions', () => {
    beforeEach(() => {
      this.initialCronInterval = '1 2 3 4 5';
      this.intervalPatternComponent = new IntervalPatternInputComponent({
        propsData: {
          initialCronInterval: this.initialCronInterval,
        },
      }).$mount();
    });

    it('cronInterval is updated when everyday preset interval is selected', (done) => {
      expect(this.intervalPatternComponent.cronInterval).toBe(this.initialCronInterval);

      this.intervalPatternComponent.$el.querySelector('#every-day').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.cronInterval).toBe(cronIntervalPresets.everyDay);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').value).toBe(cronIntervalPresets.everyDay);
        done();
      });
    });

    it('cronInterval is updated when everyweek preset interval is selected', (done) => {
      expect(this.intervalPatternComponent.cronInterval).toBe(this.initialCronInterval);

      this.intervalPatternComponent.$el.querySelector('#every-week').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.cronInterval).toBe(cronIntervalPresets.everyWeek);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').value).toBe(cronIntervalPresets.everyWeek);

        done();
      });
    });

    it('cronInterval is updated when everymonth preset interval is selected', (done) => {
      expect(this.intervalPatternComponent.cronInterval).toBe(this.initialCronInterval);

      this.intervalPatternComponent.$el.querySelector('#every-month').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.cronInterval).toBe(cronIntervalPresets.everyMonth);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').value).toBe(cronIntervalPresets.everyMonth);
        done();
      });
    });

    it('only a space is added to cronInterval (trimmed later) when custom radio is selected', (done) => {
      expect(this.intervalPatternComponent.cronInterval).toBe(this.initialCronInterval);

      this.intervalPatternComponent.$el.querySelector('#every-month').click();
      this.intervalPatternComponent.$el.querySelector('#custom').click();

      Vue.nextTick(() => {
        const intervalWithSpaceAppended = `${cronIntervalPresets.everyMonth} `;
        expect(this.intervalPatternComponent.cronInterval).toBe(intervalWithSpaceAppended);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').value).toBe(intervalWithSpaceAppended);
        done();
      });
    });

    it('text input is disabled when preset interval is selected', (done) => {
      this.intervalPatternComponent.$el.querySelector('#every-month').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.isEditable).toBe(false);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').disabled).toBe(true);
        done();
      });
    });

    it('text input is enabled when custom is selected', (done) => {
      this.intervalPatternComponent.$el.querySelector('#every-month').click();
      this.intervalPatternComponent.$el.querySelector('#custom').click();

      Vue.nextTick(() => {
        expect(this.intervalPatternComponent.isEditable).toBe(true);
        expect(this.intervalPatternComponent.$el.querySelector('.cron-interval-input').disabled).toBe(false);
        done();
      });
    });
  });
});
