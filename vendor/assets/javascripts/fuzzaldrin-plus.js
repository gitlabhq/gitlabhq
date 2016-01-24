/*!
 * fuzzaldrin-plus.js - 0.3.1
 * https://github.com/jeancroy/fuzzaldrin-plus
 *
 * Copyright 2016 - Jean Christophe Roy
 * Released under the MIT license
 * https://github.com/jeancroy/fuzzaldrin-plus/raw/master/LICENSE.md
 */
(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
fuzzaldrinPlus = require('fuzzaldrin-plus');

},{"fuzzaldrin-plus":3}],2:[function(require,module,exports){
(function() {
  var PathSeparator, legacy_scorer, pluckCandidates, scorer, sortCandidates;

  scorer = require('./scorer');

  legacy_scorer = require('./legacy');

  pluckCandidates = function(a) {
    return a.candidate;
  };

  sortCandidates = function(a, b) {
    return b.score - a.score;
  };

  PathSeparator = require('path').sep;

  module.exports = function(candidates, query, _arg) {
    var allowErrors, bAllowErrors, bKey, candidate, coreQuery, key, legacy, maxInners, maxResults, prepQuery, queryHasSlashes, score, scoredCandidates, spotLeft, string, _i, _j, _len, _len1, _ref;
    _ref = _arg != null ? _arg : {}, key = _ref.key, maxResults = _ref.maxResults, maxInners = _ref.maxInners, allowErrors = _ref.allowErrors, legacy = _ref.legacy;
    scoredCandidates = [];
    spotLeft = (maxInners != null) && maxInners > 0 ? maxInners : candidates.length;
    bAllowErrors = !!allowErrors;
    bKey = key != null;
    prepQuery = scorer.prepQuery(query);
    if (!legacy) {
      for (_i = 0, _len = candidates.length; _i < _len; _i++) {
        candidate = candidates[_i];
        string = bKey ? candidate[key] : candidate;
        if (!string) {
          continue;
        }
        score = scorer.score(string, query, prepQuery, bAllowErrors);
        if (score > 0) {
          scoredCandidates.push({
            candidate: candidate,
            score: score
          });
          if (!--spotLeft) {
            break;
          }
        }
      }
    } else {
      queryHasSlashes = prepQuery.depth > 0;
      coreQuery = prepQuery.core;
      for (_j = 0, _len1 = candidates.length; _j < _len1; _j++) {
        candidate = candidates[_j];
        string = key != null ? candidate[key] : candidate;
        if (!string) {
          continue;
        }
        score = legacy_scorer.score(string, coreQuery, queryHasSlashes);
        if (!queryHasSlashes) {
          score = legacy_scorer.basenameScore(string, coreQuery, score);
        }
        if (score > 0) {
          scoredCandidates.push({
            candidate: candidate,
            score: score
          });
        }
      }
    }
    scoredCandidates.sort(sortCandidates);
    candidates = scoredCandidates.map(pluckCandidates);
    if (maxResults != null) {
      candidates = candidates.slice(0, maxResults);
    }
    return candidates;
  };

}).call(this);

},{"./legacy":4,"./scorer":6,"path":7}],3:[function(require,module,exports){
(function() {
  var PathSeparator, filter, legacy_scorer, matcher, prepQueryCache, scorer;

  scorer = require('./scorer');

  legacy_scorer = require('./legacy');

  filter = require('./filter');

  matcher = require('./matcher');

  PathSeparator = require('path').sep;

  prepQueryCache = null;

  module.exports = {
    filter: function(candidates, query, options) {
      if (!((query != null ? query.length : void 0) && (candidates != null ? candidates.length : void 0))) {
        return [];
      }
      return filter(candidates, query, options);
    },
    prepQuery: function(query) {
      return scorer.prepQuery(query);
    },
    score: function(string, query, prepQuery, _arg) {
      var allowErrors, coreQuery, legacy, queryHasSlashes, score, _ref;
      _ref = _arg != null ? _arg : {}, allowErrors = _ref.allowErrors, legacy = _ref.legacy;
      if (!((string != null ? string.length : void 0) && (query != null ? query.length : void 0))) {
        return 0;
      }
      if (prepQuery == null) {
        prepQuery = prepQueryCache && prepQueryCache.query === query ? prepQueryCache : (prepQueryCache = scorer.prepQuery(query));
      }
      if (!legacy) {
        score = scorer.score(string, query, prepQuery, !!allowErrors);
      } else {
        queryHasSlashes = prepQuery.depth > 0;
        coreQuery = prepQuery.core;
        score = legacy_scorer.score(string, coreQuery, queryHasSlashes);
        if (!queryHasSlashes) {
          score = legacy_scorer.basenameScore(string, coreQuery, score);
        }
      }
      return score;
    },
    match: function(string, query, prepQuery, _arg) {
      var allowErrors, baseMatches, matches, query_lw, string_lw, _i, _ref, _results;
      allowErrors = (_arg != null ? _arg : {}).allowErrors;
      if (!string) {
        return [];
      }
      if (!query) {
        return [];
      }
      if (string === query) {
        return (function() {
          _results = [];
          for (var _i = 0, _ref = string.length; 0 <= _ref ? _i < _ref : _i > _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this);
      }
      if (prepQuery == null) {
        prepQuery = prepQueryCache && prepQueryCache.query === query ? prepQueryCache : (prepQueryCache = scorer.prepQuery(query));
      }
      if (!(allowErrors || scorer.isMatch(string, prepQuery.core_lw, prepQuery.core_up))) {
        return [];
      }
      string_lw = string.toLowerCase();
      query_lw = prepQuery.query_lw;
      matches = matcher.match(string, string_lw, prepQuery);
      if (matches.length === 0) {
        return matches;
      }
      if (string.indexOf(PathSeparator) > -1) {
        baseMatches = matcher.basenameMatch(string, string_lw, prepQuery);
        matches = matcher.mergeMatches(matches, baseMatches);
      }
      return matches;
    }
  };

}).call(this);

},{"./filter":2,"./legacy":4,"./matcher":5,"./scorer":6,"path":7}],4:[function(require,module,exports){
(function() {
  var PathSeparator, queryIsLastPathSegment;

  PathSeparator = require('path').sep;

  exports.basenameScore = function(string, query, score) {
    var base, depth, index, lastCharacter, segmentCount, slashCount;
    index = string.length - 1;
    while (string[index] === PathSeparator) {
      index--;
    }
    slashCount = 0;
    lastCharacter = index;
    base = null;
    while (index >= 0) {
      if (string[index] === PathSeparator) {
        slashCount++;
        if (base == null) {
          base = string.substring(index + 1, lastCharacter + 1);
        }
      } else if (index === 0) {
        if (lastCharacter < string.length - 1) {
          if (base == null) {
            base = string.substring(0, lastCharacter + 1);
          }
        } else {
          if (base == null) {
            base = string;
          }
        }
      }
      index--;
    }
    if (base === string) {
      score *= 2;
    } else if (base) {
      score += exports.score(base, query);
    }
    segmentCount = slashCount + 1;
    depth = Math.max(1, 10 - segmentCount);
    score *= depth * 0.01;
    return score;
  };

  exports.score = function(string, query) {
    var character, characterScore, indexInQuery, indexInString, lowerCaseIndex, minIndex, queryLength, queryScore, stringLength, totalCharacterScore, upperCaseIndex, _ref;
    if (string === query) {
      return 1;
    }
    if (queryIsLastPathSegment(string, query)) {
      return 1;
    }
    totalCharacterScore = 0;
    queryLength = query.length;
    stringLength = string.length;
    indexInQuery = 0;
    indexInString = 0;
    while (indexInQuery < queryLength) {
      character = query[indexInQuery++];
      lowerCaseIndex = string.indexOf(character.toLowerCase());
      upperCaseIndex = string.indexOf(character.toUpperCase());
      minIndex = Math.min(lowerCaseIndex, upperCaseIndex);
      if (minIndex === -1) {
        minIndex = Math.max(lowerCaseIndex, upperCaseIndex);
      }
      indexInString = minIndex;
      if (indexInString === -1) {
        return 0;
      }
      characterScore = 0.1;
      if (string[indexInString] === character) {
        characterScore += 0.1;
      }
      if (indexInString === 0 || string[indexInString - 1] === PathSeparator) {
        characterScore += 0.8;
      } else if ((_ref = string[indexInString - 1]) === '-' || _ref === '_' || _ref === ' ') {
        characterScore += 0.7;
      }
      string = string.substring(indexInString + 1, stringLength);
      totalCharacterScore += characterScore;
    }
    queryScore = totalCharacterScore / queryLength;
    return ((queryScore * (queryLength / stringLength)) + queryScore) / 2;
  };

  queryIsLastPathSegment = function(string, query) {
    if (string[string.length - query.length - 1] === PathSeparator) {
      return string.lastIndexOf(query) === string.length - query.length;
    }
  };

  exports.match = function(string, query, stringOffset) {
    var character, indexInQuery, indexInString, lowerCaseIndex, matches, minIndex, queryLength, stringLength, upperCaseIndex, _i, _ref, _results;
    if (stringOffset == null) {
      stringOffset = 0;
    }
    if (string === query) {
      return (function() {
        _results = [];
        for (var _i = stringOffset, _ref = stringOffset + string.length; stringOffset <= _ref ? _i < _ref : _i > _ref; stringOffset <= _ref ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this);
    }
    queryLength = query.length;
    stringLength = string.length;
    indexInQuery = 0;
    indexInString = 0;
    matches = [];
    while (indexInQuery < queryLength) {
      character = query[indexInQuery++];
      lowerCaseIndex = string.indexOf(character.toLowerCase());
      upperCaseIndex = string.indexOf(character.toUpperCase());
      minIndex = Math.min(lowerCaseIndex, upperCaseIndex);
      if (minIndex === -1) {
        minIndex = Math.max(lowerCaseIndex, upperCaseIndex);
      }
      indexInString = minIndex;
      if (indexInString === -1) {
        return [];
      }
      matches.push(stringOffset + indexInString);
      stringOffset += indexInString + 1;
      string = string.substring(indexInString + 1, stringLength);
    }
    return matches;
  };

}).call(this);

},{"path":7}],5:[function(require,module,exports){
(function() {
  var PathSeparator, scorer;

  PathSeparator = require('path').sep;

  scorer = require('./scorer');

  exports.basenameMatch = function(subject, subject_lw, prepQuery) {
    var basePos, depth, end;
    end = subject.length - 1;
    while (subject[end] === PathSeparator) {
      end--;
    }
    basePos = subject.lastIndexOf(PathSeparator, end);
    if (basePos === -1) {
      return [];
    }
    depth = prepQuery.depth;
    while (depth-- > 0) {
      basePos = subject.lastIndexOf(PathSeparator, basePos - 1);
      if (basePos === -1) {
        return [];
      }
    }
    basePos++;
    end++;
    return exports.match(subject.slice(basePos, end), subject_lw.slice(basePos, end), prepQuery, basePos);
  };

  exports.mergeMatches = function(a, b) {
    var ai, bj, i, j, m, n, out;
    m = a.length;
    n = b.length;
    if (n === 0) {
      return a.slice();
    }
    if (m === 0) {
      return b.slice();
    }
    i = -1;
    j = 0;
    bj = b[j];
    out = [];
    while (++i < m) {
      ai = a[i];
      while (bj <= ai && ++j < n) {
        if (bj < ai) {
          out.push(bj);
        }
        bj = b[j];
      }
      out.push(ai);
    }
    while (j < n) {
      out.push(b[j++]);
    }
    return out;
  };

  exports.match = function(subject, subject_lw, prepQuery, offset) {
    var DIAGONAL, LEFT, STOP, UP, acro_score, align, backtrack, csc_diag, csc_row, csc_score, i, j, m, matches, move, n, pos, query, query_lw, score, score_diag, score_row, score_up, si_lw, start, trace;
    if (offset == null) {
      offset = 0;
    }
    query = prepQuery.query;
    query_lw = prepQuery.query_lw;
    m = subject.length;
    n = query.length;
    acro_score = scorer.scoreAcronyms(subject, subject_lw, query, query_lw).score;
    score_row = new Array(n);
    csc_row = new Array(n);
    STOP = 0;
    UP = 1;
    LEFT = 2;
    DIAGONAL = 3;
    trace = new Array(m * n);
    pos = -1;
    j = -1;
    while (++j < n) {
      score_row[j] = 0;
      csc_row[j] = 0;
    }
    i = -1;
    while (++i < m) {
      score = 0;
      score_up = 0;
      csc_diag = 0;
      si_lw = subject_lw[i];
      j = -1;
      while (++j < n) {
        csc_score = 0;
        align = 0;
        score_diag = score_up;
        if (query_lw[j] === si_lw) {
          start = scorer.isWordStart(i, subject, subject_lw);
          csc_score = csc_diag > 0 ? csc_diag : scorer.scoreConsecutives(subject, subject_lw, query, query_lw, i, j, start);
          align = score_diag + scorer.scoreCharacter(i, j, start, acro_score, csc_score);
        }
        score_up = score_row[j];
        csc_diag = csc_row[j];
        if (score > score_up) {
          move = LEFT;
        } else {
          score = score_up;
          move = UP;
        }
        if (align > score) {
          score = align;
          move = DIAGONAL;
        } else {
          csc_score = 0;
        }
        score_row[j] = score;
        csc_row[j] = csc_score;
        trace[++pos] = score > 0 ? move : STOP;
      }
    }
    i = m - 1;
    j = n - 1;
    pos = i * n + j;
    backtrack = true;
    matches = [];
    while (backtrack && i >= 0 && j >= 0) {
      switch (trace[pos]) {
        case UP:
          i--;
          pos -= n;
          break;
        case LEFT:
          j--;
          pos--;
          break;
        case DIAGONAL:
          matches.push(i + offset);
          j--;
          i--;
          pos -= n + 1;
          break;
        default:
          backtrack = false;
      }
    }
    matches.reverse();
    return matches;
  };

}).call(this);

},{"./scorer":6,"path":7}],6:[function(require,module,exports){
(function() {
  var AcronymResult, PathSeparator, Query, basenameScore, coreChars, countDir, doScore, emptyAcronymResult, file_coeff, isMatch, isSeparator, isWordEnd, isWordStart, miss_coeff, opt_char_re, pos_bonus, scoreAcronyms, scoreCharacter, scoreConsecutives, scoreExact, scoreExactMatch, scorePattern, scorePosition, scoreSize, tau_depth, tau_size, truncatedUpperCase, wm;

  PathSeparator = require('path').sep;

  wm = 150;

  pos_bonus = 20;

  tau_depth = 13;

  tau_size = 85;

  file_coeff = 1.2;

  miss_coeff = 0.75;

  opt_char_re = /[ _\-:\/\\]/g;

  exports.coreChars = coreChars = function(query) {
    return query.replace(opt_char_re, '');
  };

  exports.score = function(string, query, prepQuery, allowErrors) {
    var score, string_lw;
    if (prepQuery == null) {
      prepQuery = new Query(query);
    }
    if (allowErrors == null) {
      allowErrors = false;
    }
    if (!(allowErrors || isMatch(string, prepQuery.core_lw, prepQuery.core_up))) {
      return 0;
    }
    string_lw = string.toLowerCase();
    score = doScore(string, string_lw, prepQuery);
    return Math.ceil(basenameScore(string, string_lw, prepQuery, score));
  };

  Query = (function() {
    function Query(query) {
      if (!(query != null ? query.length : void 0)) {
        return null;
      }
      this.query = query;
      this.query_lw = query.toLowerCase();
      this.core = coreChars(query);
      this.core_lw = this.core.toLowerCase();
      this.core_up = truncatedUpperCase(this.core);
      this.depth = countDir(query, query.length);
    }

    return Query;

  })();

  exports.prepQuery = function(query) {
    return new Query(query);
  };

  exports.isMatch = isMatch = function(subject, query_lw, query_up) {
    var i, j, m, n, qj_lw, qj_up, si;
    m = subject.length;
    n = query_lw.length;
    if (!m || n > m) {
      return false;
    }
    i = -1;
    j = -1;
    while (++j < n) {
      qj_lw = query_lw[j];
      qj_up = query_up[j];
      while (++i < m) {
        si = subject[i];
        if (si === qj_lw || si === qj_up) {
          break;
        }
      }
      if (i === m) {
        return false;
      }
    }
    return true;
  };

  doScore = function(subject, subject_lw, prepQuery) {
    var acro, acro_score, align, csc_diag, csc_row, csc_score, i, j, m, miss_budget, miss_left, mm, n, pos, query, query_lw, record_miss, score, score_diag, score_row, score_up, si_lw, start, sz;
    query = prepQuery.query;
    query_lw = prepQuery.query_lw;
    m = subject.length;
    n = query.length;
    acro = scoreAcronyms(subject, subject_lw, query, query_lw);
    acro_score = acro.score;
    if (acro.count === n) {
      return scoreExact(n, m, acro_score, acro.pos);
    }
    pos = subject_lw.indexOf(query_lw);
    if (pos > -1) {
      return scoreExactMatch(subject, subject_lw, query, query_lw, pos, n, m);
    }
    score_row = new Array(n);
    csc_row = new Array(n);
    sz = scoreSize(n, m);
    miss_budget = Math.ceil(miss_coeff * n) + 5;
    miss_left = miss_budget;
    j = -1;
    while (++j < n) {
      score_row[j] = 0;
      csc_row[j] = 0;
    }
    i = subject_lw.indexOf(query_lw[0]);
    if (i > -1) {
      i--;
    }
    mm = subject_lw.lastIndexOf(query_lw[n - 1], m);
    if (mm > i) {
      m = mm + 1;
    }
    while (++i < m) {
      score = 0;
      score_diag = 0;
      csc_diag = 0;
      si_lw = subject_lw[i];
      record_miss = true;
      j = -1;
      while (++j < n) {
        score_up = score_row[j];
        if (score_up > score) {
          score = score_up;
        }
        csc_score = 0;
        if (query_lw[j] === si_lw) {
          start = isWordStart(i, subject, subject_lw);
          csc_score = csc_diag > 0 ? csc_diag : scoreConsecutives(subject, subject_lw, query, query_lw, i, j, start);
          align = score_diag + scoreCharacter(i, j, start, acro_score, csc_score);
          if (align > score) {
            score = align;
            miss_left = miss_budget;
          } else {
            if (record_miss && --miss_left <= 0) {
              return score_row[n - 1] * sz;
            }
            record_miss = false;
          }
        }
        score_diag = score_up;
        csc_diag = csc_row[j];
        csc_row[j] = csc_score;
        score_row[j] = score;
      }
    }
    return score * sz;
  };

  exports.isWordStart = isWordStart = function(pos, subject, subject_lw) {
    var curr_s, prev_s;
    if (pos === 0) {
      return true;
    }
    curr_s = subject[pos];
    prev_s = subject[pos - 1];
    return isSeparator(curr_s) || isSeparator(prev_s) || (curr_s !== subject_lw[pos] && prev_s === subject_lw[pos - 1]);
  };

  exports.isWordEnd = isWordEnd = function(pos, subject, subject_lw, len) {
    var curr_s, next_s;
    if (pos === len - 1) {
      return true;
    }
    curr_s = subject[pos];
    next_s = subject[pos + 1];
    return isSeparator(curr_s) || isSeparator(next_s) || (curr_s === subject_lw[pos] && next_s !== subject_lw[pos + 1]);
  };

  isSeparator = function(c) {
    return c === ' ' || c === '.' || c === '-' || c === '_' || c === '/' || c === '\\';
  };

  scorePosition = function(pos) {
    var sc;
    if (pos < pos_bonus) {
      sc = pos_bonus - pos;
      return 100 + sc * sc;
    } else {
      return Math.max(100 + pos_bonus - pos, 0);
    }
  };

  scoreSize = function(n, m) {
    return tau_size / (tau_size + Math.abs(m - n));
  };

  scoreExact = function(n, m, quality, pos) {
    return 2 * n * (wm * quality + scorePosition(pos)) * scoreSize(n, m);
  };

  exports.scorePattern = scorePattern = function(count, len, sameCase, start, end) {
    var bonus, sz;
    sz = count;
    bonus = 6;
    if (sameCase === count) {
      bonus += 2;
    }
    if (start) {
      bonus += 3;
    }
    if (end) {
      bonus += 1;
    }
    if (count === len) {
      if (start) {
        if (sameCase === len) {
          sz += 2;
        } else {
          sz += 1;
        }
      }
      if (end) {
        bonus += 1;
      }
    }
    return sameCase + sz * (sz + bonus);
  };

  exports.scoreCharacter = scoreCharacter = function(i, j, start, acro_score, csc_score) {
    var posBonus;
    posBonus = scorePosition(i);
    if (start) {
      return posBonus + wm * ((acro_score > csc_score ? acro_score : csc_score) + 10);
    }
    return posBonus + wm * csc_score;
  };

  exports.scoreConsecutives = scoreConsecutives = function(subject, subject_lw, query, query_lw, i, j, start) {
    var k, m, mi, n, nj, sameCase, startPos, sz;
    m = subject.length;
    n = query.length;
    mi = m - i;
    nj = n - j;
    k = mi < nj ? mi : nj;
    startPos = i;
    sameCase = 0;
    sz = 0;
    if (query[j] === subject[i]) {
      sameCase++;
    }
    while (++sz < k && query_lw[++j] === subject_lw[++i]) {
      if (query[j] === subject[i]) {
        sameCase++;
      }
    }
    if (sz === 1) {
      return 1 + 2 * sameCase;
    }
    return scorePattern(sz, n, sameCase, start, isWordEnd(i, subject, subject_lw, m));
  };

  exports.scoreExactMatch = scoreExactMatch = function(subject, subject_lw, query, query_lw, pos, n, m) {
    var end, i, pos2, sameCase, start;
    start = isWordStart(pos, subject, subject_lw);
    if (!start) {
      pos2 = subject_lw.indexOf(query_lw, pos + 1);
      if (pos2 > -1) {
        start = isWordStart(pos2, subject, subject_lw);
        if (start) {
          pos = pos2;
        }
      }
    }
    i = -1;
    sameCase = 0;
    while (++i < n) {
      if (query[pos + i] === subject[i]) {
        sameCase++;
      }
    }
    end = isWordEnd(pos + n - 1, subject, subject_lw, m);
    return scoreExact(n, m, scorePattern(n, n, sameCase, start, end), pos);
  };

  AcronymResult = (function() {
    function AcronymResult(score, pos, count) {
      this.score = score;
      this.pos = pos;
      this.count = count;
    }

    return AcronymResult;

  })();

  emptyAcronymResult = new AcronymResult(0, 0.1, 0);

  exports.scoreAcronyms = scoreAcronyms = function(subject, subject_lw, query, query_lw) {
    var count, i, j, m, n, pos, qj_lw, sameCase, score;
    m = subject.length;
    n = query.length;
    if (!(m > 1 && n > 1)) {
      return emptyAcronymResult;
    }
    count = 0;
    pos = 0;
    sameCase = 0;
    i = -1;
    j = -1;
    while (++j < n) {
      qj_lw = query_lw[j];
      while (++i < m) {
        if (qj_lw === subject_lw[i] && isWordStart(i, subject, subject_lw)) {
          if (query[j] === subject[i]) {
            sameCase++;
          }
          pos += i;
          count++;
          break;
        }
      }
      if (i === m) {
        break;
      }
    }
    if (count < 2) {
      return emptyAcronymResult;
    }
    score = scorePattern(count, n, sameCase, true, false);
    return new AcronymResult(score, pos / count, count);
  };

  basenameScore = function(subject, subject_lw, prepQuery, fullPathScore) {
    var alpha, basePathScore, basePos, depth, end;
    if (fullPathScore === 0) {
      return 0;
    }
    end = subject.length - 1;
    while (subject[end] === PathSeparator) {
      end--;
    }
    basePos = subject.lastIndexOf(PathSeparator, end);
    if (basePos === -1) {
      return fullPathScore;
    }
    depth = prepQuery.depth;
    while (depth-- > 0) {
      basePos = subject.lastIndexOf(PathSeparator, basePos - 1);
      if (basePos === -1) {
        return fullPathScore;
      }
    }
    basePos++;
    end++;
    basePathScore = doScore(subject.slice(basePos, end), subject_lw.slice(basePos, end), prepQuery);
    alpha = 0.5 * tau_depth / (tau_depth + countDir(subject, end + 1));
    return alpha * basePathScore + (1 - alpha) * fullPathScore * scoreSize(0, file_coeff * (end - basePos));
  };

  exports.countDir = countDir = function(path, end) {
    var count, i;
    if (end < 1) {
      return 0;
    }
    count = 0;
    i = -1;
    while (++i < end && path[i] === PathSeparator) {
      continue;
    }
    while (++i < end) {
      if (path[i] === PathSeparator) {
        count++;
        while (++i < end && path[i] === PathSeparator) {
          continue;
        }
      }
    }
    return count;
  };

  truncatedUpperCase = function(str) {
    var char, upper, _i, _len;
    upper = "";
    for (_i = 0, _len = str.length; _i < _len; _i++) {
      char = str[_i];
      upper += char.toUpperCase()[0];
    }
    return upper;
  };

}).call(this);

},{"path":7}],7:[function(require,module,exports){
(function (process){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

// resolves . and .. elements in a path array with directory names there
// must be no slashes, empty elements, or device names (c:\) in the array
// (so also no leading and trailing slashes - it does not distinguish
// relative and absolute paths)
function normalizeArray(parts, allowAboveRoot) {
  // if the path tries to go above the root, `up` ends up > 0
  var up = 0;
  for (var i = parts.length - 1; i >= 0; i--) {
    var last = parts[i];
    if (last === '.') {
      parts.splice(i, 1);
    } else if (last === '..') {
      parts.splice(i, 1);
      up++;
    } else if (up) {
      parts.splice(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (allowAboveRoot) {
    for (; up--; up) {
      parts.unshift('..');
    }
  }

  return parts;
}

// Split a filename into [root, dir, basename, ext], unix version
// 'root' is just a slash, or nothing.
var splitPathRe =
    /^(\/?|)([\s\S]*?)((?:\.{1,2}|[^\/]+?|)(\.[^.\/]*|))(?:[\/]*)$/;
var splitPath = function(filename) {
  return splitPathRe.exec(filename).slice(1);
};

// path.resolve([from ...], to)
// posix version
exports.resolve = function() {
  var resolvedPath = '',
      resolvedAbsolute = false;

  for (var i = arguments.length - 1; i >= -1 && !resolvedAbsolute; i--) {
    var path = (i >= 0) ? arguments[i] : process.cwd();

    // Skip empty and invalid entries
    if (typeof path !== 'string') {
      throw new TypeError('Arguments to path.resolve must be strings');
    } else if (!path) {
      continue;
    }

    resolvedPath = path + '/' + resolvedPath;
    resolvedAbsolute = path.charAt(0) === '/';
  }

  // At this point the path should be resolved to a full absolute path, but
  // handle relative paths to be safe (might happen when process.cwd() fails)

  // Normalize the path
  resolvedPath = normalizeArray(filter(resolvedPath.split('/'), function(p) {
    return !!p;
  }), !resolvedAbsolute).join('/');

  return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
};

// path.normalize(path)
// posix version
exports.normalize = function(path) {
  var isAbsolute = exports.isAbsolute(path),
      trailingSlash = substr(path, -1) === '/';

  // Normalize the path
  path = normalizeArray(filter(path.split('/'), function(p) {
    return !!p;
  }), !isAbsolute).join('/');

  if (!path && !isAbsolute) {
    path = '.';
  }
  if (path && trailingSlash) {
    path += '/';
  }

  return (isAbsolute ? '/' : '') + path;
};

// posix version
exports.isAbsolute = function(path) {
  return path.charAt(0) === '/';
};

// posix version
exports.join = function() {
  var paths = Array.prototype.slice.call(arguments, 0);
  return exports.normalize(filter(paths, function(p, index) {
    if (typeof p !== 'string') {
      throw new TypeError('Arguments to path.join must be strings');
    }
    return p;
  }).join('/'));
};


// path.relative(from, to)
// posix version
exports.relative = function(from, to) {
  from = exports.resolve(from).substr(1);
  to = exports.resolve(to).substr(1);

  function trim(arr) {
    var start = 0;
    for (; start < arr.length; start++) {
      if (arr[start] !== '') break;
    }

    var end = arr.length - 1;
    for (; end >= 0; end--) {
      if (arr[end] !== '') break;
    }

    if (start > end) return [];
    return arr.slice(start, end - start + 1);
  }

  var fromParts = trim(from.split('/'));
  var toParts = trim(to.split('/'));

  var length = Math.min(fromParts.length, toParts.length);
  var samePartsLength = length;
  for (var i = 0; i < length; i++) {
    if (fromParts[i] !== toParts[i]) {
      samePartsLength = i;
      break;
    }
  }

  var outputParts = [];
  for (var i = samePartsLength; i < fromParts.length; i++) {
    outputParts.push('..');
  }

  outputParts = outputParts.concat(toParts.slice(samePartsLength));

  return outputParts.join('/');
};

exports.sep = '/';
exports.delimiter = ':';

exports.dirname = function(path) {
  var result = splitPath(path),
      root = result[0],
      dir = result[1];

  if (!root && !dir) {
    // No dirname whatsoever
    return '.';
  }

  if (dir) {
    // It has a dirname, strip trailing slash
    dir = dir.substr(0, dir.length - 1);
  }

  return root + dir;
};


exports.basename = function(path, ext) {
  var f = splitPath(path)[2];
  // TODO: make this comparison case-insensitive on windows?
  if (ext && f.substr(-1 * ext.length) === ext) {
    f = f.substr(0, f.length - ext.length);
  }
  return f;
};


exports.extname = function(path) {
  return splitPath(path)[3];
};

function filter (xs, f) {
    if (xs.filter) return xs.filter(f);
    var res = [];
    for (var i = 0; i < xs.length; i++) {
        if (f(xs[i], i, xs)) res.push(xs[i]);
    }
    return res;
}

// String.prototype.substr - negative index don't work in IE8
var substr = 'ab'.substr(-1) === 'b'
    ? function (str, start, len) { return str.substr(start, len) }
    : function (str, start, len) {
        if (start < 0) start = str.length + start;
        return str.substr(start, len);
    }
;

}).call(this,require('_process'))
},{"_process":8}],8:[function(require,module,exports){
// shim for using process in browser

var process = module.exports = {};
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = setTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            if (currentQueue) {
                currentQueue[queueIndex].run();
            }
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    clearTimeout(timeout);
}

process.nextTick = function (fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (queue.length === 1 && !draining) {
        setTimeout(drainQueue, 0);
    }
};

// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };

},{}]},{},[1]);
