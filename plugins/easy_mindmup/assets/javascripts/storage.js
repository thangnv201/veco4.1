(function () {
  'use strict';
  /**
   *
   * @param {MindMup} ysy
   * @property {StorageExtra} extra
   * @property {StorageLastState} lastState
   * @property {StorageSettings} settings
   * @constructor
   */
  function Storage(ysy) {
    this._scope = ysy.id + "-";
    this.ysy = ysy;
    this.extra = new StorageExtra(this);
    var lastState = new StorageLastState(this);
    var settings = new StorageSettings(this);
    this.lastState = lastState;
    this.settings = settings;
    var self = this;
    //if (this._scope == null) throw "_scope is not defined! Scope is used for separation of xBS products in localStorage";

    ysy.eventBus.register("TreeLoaded", function (idea) {
      idea.addEventListener('changed', function () {
        lastState.remove();
        self.save(idea);
      });
    });

  }

  Storage.prototype.getSessionData = function (key) {
    return window.sessionStorage.getItem(this._scope + key);
  };
  Storage.prototype.saveSessionData = function (key, value) {
    window.sessionStorage.setItem(this._scope + key, value);
  };
  Storage.prototype.resetSessionData = function (key) {
    window.sessionStorage.removeItem(this._scope + key);
  };
  Storage.prototype.getPersistentData = function (key) {
    return window.localStorage.getItem(this._scope + key);
  };
  Storage.prototype.savePersistentData = function (key, value) {
    window.localStorage.setItem(this._scope + key, value);
  };
  Storage.prototype.resetPersistentData = function (key) {
    window.localStorage.removeItem(this._scope + key);
  };
  Storage.prototype.save = function (idea) {
    this.extra.save(idea);
    this.lastState.save(idea);
  };
  Storage.prototype.clear = function () {
    this.lastState.remove();
    this.extra.positionExtract = null;
  };
  window.easyMindMupClasses = window.easyMindMupClasses || {};
  window.easyMindMupClasses.Storage = Storage;

//###################################################################################################
  /**
   *
   * @param {Storage} storage
   * @constructor
   */
  function StorageExtra(storage) {
    this.positionExtract = null;
    this.collapseExtract = null;
    this.storage = storage;
    /** @type {MindMup} ysy */
    this.ysy = storage.ysy;
    /** @param {ModelEntity} idea */
    this._getIdOfIdea = function (idea) {
      // Override this for proper entity type prefixing
      // (to prevent having same id for different entities)
      return this.ysy.getData(idea).id;
    };
  }

  StorageExtra.prototype._key = "extra-";
  /**
   *
   * @param {RootIdea} idea
   */
  StorageExtra.prototype.save = function (idea) {
    if (!idea) return;
    var extract = this._extractFromNode(idea);
    this.positionExtract = extract.positions;
    this.collapseExtract = extract.collapses;
    var toSave = {
      collapses: this.collapseExtract,
      rootPos: {
        deltaX: this.ysy.domPatch.deltaX,
        deltaY: this.ysy.domPatch.deltaY
      }
    };

    this.storage.savePersistentData(this._key + this._getIdOfIdea(idea), JSON.stringify(toSave));
  };
  /**
   * @param {RootIdea} idea
   * return {{collapses:Object, rootPos: Object}}
   */
  StorageExtra.prototype.getLocalProjectData = function (idea) {
    var json = this.storage.getPersistentData(this._key + this._getIdOfIdea(idea));
    if (json === null || json === "") return {};
    var result = JSON.parse(json) || {};
    if (!result.collapses) return {collapses: result};
    return result;
  };
  /**
   *
   * @param {Array.<ModelEntity>} data
   * @param {RootIdea} root
   * @return {Array.<ModelEntity>}
   */
  StorageExtra.prototype.enhanceData = function (data, root) {
    /** @type {Object.<string,{position:Object,rank:number}>} */
    var positions = this.positionExtract;
    var projectData = this.getLocalProjectData(root);
    var collapses = projectData.collapses;
    this.ysy.domPatch.loadRootPosition(projectData.rootPos);
    if (positions) {
      for (var i = 1; i < data.length; i++) {
        var nodeExtract = positions[this._getIdOfIdea(data[i])];
        if (!nodeExtract) continue;
        if (nodeExtract.position) {
          var position = [];
          for (var j = 0; j < nodeExtract.position.length; j++) {
            position.push(parseFloat(nodeExtract.position[j]));
          }
          data[i].attr.position = position;
        }
        data[i].rank = nodeExtract.rank;
        // data[i]._parentTitle = nodeExtract.parentTitle;
      }
    }
    if (collapses) {
      for (i = 1; i < data.length; i++) {
        data[i].attr.collapsed = !!collapses[this._getIdOfIdea(data[i])];
      }
    }
    return data;
  };
  /**
   * @param {{code?:String}} layout
   */
  StorageExtra.prototype.setLayout = function (layout) {
    this.positionExtract = this._decodeLayout(layout);
  };
  /**
   * @return {{code?: String}}
   */
  StorageExtra.prototype.getLayout = function () {
    return this._encodeLayout(this.positionExtract);
  };
  /**
   * encode layout if it contains more than 50 keys.
   * result is capped if it reaches 60000 characters
   * @param {{}} decodedLayout
   * @return {{code?:String}|null}
   */
  StorageExtra.prototype._encodeLayout = function (decodedLayout) {
    if(!decodedLayout) return null;
    var keys = Object.getOwnPropertyNames(decodedLayout);
    if (keys.length <= 50) return decodedLayout;
    var i, key, pos, result = "";
    if (keys.length > 2000) {
      for (i = 0; i < keys.length; i++) {
        key = keys[i];
        pos = decodedLayout[key].position ? ("[" + decodedLayout[key].position + "]") : "";
        result += key + "{" + (decodedLayout[key].rank || "") + pos + "}";
        if (result.length > 60000) return {code: result};
      }
    } else {
      for (i = 0; i < keys.length; i++) {
        key = keys[i];
        pos = decodedLayout[key].position ? ("[" + decodedLayout[key].position + "]") : "";
        result += key + "{" + (decodedLayout[key].rank || "") + pos + "}";
      }

    }
    return {code: result};
  };
  /**
   * decode layout if contains "code" key
   * @param {{code?:String}} encodedLayout
   * @return {{}|null}
   */
  StorageExtra.prototype._decodeLayout = function (encodedLayout) {
    if (!encodedLayout) return null;
    if (!encodedLayout.code) return encodedLayout;
    var issueStrings = encodedLayout.code.split("}");
    var result = {};
    for (var i = 0; i < issueStrings.length; i++) {
      var issueString = issueStrings[i];
      var p = issueString.indexOf("{");
      if (p === -1) continue;
      var issueResult = {};
      var key = issueString.substring(0, p);
      result[key] = issueResult;
      var k = issueString.indexOf("[");
      var issueRank;
      if (k > -1) {
        var posString = issueString.substring(k);
        issueResult.position = JSON.parse(posString);
        issueRank = issueString.substring(p + 1, k);
      } else {
        issueRank = issueString.substring(p + 1);
      }
      if (issueRank) {
        issueResult.rank = parseInt(issueRank);
      }
    }
    return result;
  };

  /**
   *
   * @param {ModelEntity} node
   * @param {string|number} [rank]
   * @param {{positions:Object.<string,{position:Object,rank:number}>,collapses:Object.<string,boolean>}} [extract]
   * @return {{positions:Object.<string,{position:Object,rank:number}>,collapses:Object.<string,boolean>}}
   * @private
   */
  StorageExtra.prototype._extractFromNode = function (node, rank, extract) {
    if (extract === undefined) extract = {positions: {}, collapses: {}};
    var positionExtract = {};
    positionExtract.rank = rank;
    // positionExtract.parentTitle = parentTitle;
    // var data = this.ysy.getData(node);
    // if (!data.id) {
    //   positionExtract.title = node.title;
    // }
    if (node.attr.position) {
      positionExtract.position = node.attr.position;
    }
    if (node.attr.collapsed && !_.isEmpty(node.ideas)) {
      extract.collapses[this._getIdOfIdea(node)] = true;
    }
    if (node.ideas) {
      var sortedKeys = this.ysy.util.getSortedRanks(node.ideas);
      var correctedRanks = this.ysy.util.correctRanks(sortedKeys);
      for (var i = 0; i < correctedRanks.length; i++) {
        this._extractFromNode(node.ideas[sortedKeys[i]], correctedRanks[i], extract);
      }
    }
    extract.positions[this._getIdOfIdea(node)] = positionExtract;
    return extract;
  };
//#######################################################################################
  /**
   *
   * @param {Storage} storage
   * @constructor
   */
  function StorageLastState(storage) {
    this.storage = storage;
    this._binded = false;
    this.ysy = storage.ysy;
  }

  StorageLastState.prototype._dataKey = "last-data";
  StorageLastState.prototype._idKey = "last-id";
  StorageLastState.prototype.save = function (idea) {
    // this.storage.savePersistentData(this._dataKey, JSON.stringify(idea));
    // this.storage.savePersistentData(this._idKey, this.ysy.settings.rootID);
    // if (this._binded)return;
    // this._binded = true;
    // var storage = this.storage;
    // $(window).unbind('beforeunload').bind('beforeunload', function (e) {
    //   var message = "Some changes are not saved!";
    //   e.returnValue = message;
    //   return message;
    // }).unbind('unload').bind('unload', function () {
    //   storage.lastState.remove();
    // });
  };
  /**
   *
   * @return {RootIdea}
   */
  StorageLastState.prototype.getSavedIdea = function () {
    var oldId = this.storage.getPersistentData(this._idKey);
    if (oldId && parseInt(oldId) !== this.ysy.settings.rootID) {
      this.remove();
    }
    var ideaJson = this.storage.getPersistentData(this._dataKey);
    if (!ideaJson) return null;

    var idea = new window.easyMindMupClasses.RootIdea(this.ysy).fromJson(JSON.parse(ideaJson));
    return MAPJS.content(idea);
  };
  StorageLastState.prototype.remove = function () {
    this.storage.resetPersistentData(this._dataKey);
    this.storage.resetPersistentData(this._idKey);
    if (this._binded) {
      $(window).unbind('beforeunload');
      $(window).unbind('unload');
      this._binded = false;
    }
  };
  StorageLastState.prototype.compareIdea = function (idea, diffType, savedIdea) {
    if (!savedIdea) {
      savedIdea = this.getSavedIdea();
      if (savedIdea === null) {
        return null;
      }
    }
    return recursiveDiff(savedIdea, idea, {
      softParams: diffType === 'all' || diffType === 'soft',
      data: diffType === 'all' || diffType === 'data' || diffType === 'server',
      structure: diffType === 'all' || diffType === 'structure' || diffType === 'server'
    });
  };
  var recursiveDiff = function (oldIdea, newIdea, diffTypes) {
    var isDifferent = false;
    var oldDiff = {};
    var newDiff = {};
    var keys = ["title"];
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i];
      if (oldIdea[key] !== newIdea[key]) {
        oldDiff[key] = oldIdea[key];
        newDiff[key] = newIdea[key];
        isDifferent = true;
      }
    }
    if (diffTypes.data) {
      var oldData = this.ysy.getData(oldIdea);
      var newData = this.ysy.getData(newIdea);
      keys = _.union(Object.getOwnPropertyNames(oldData), Object.getOwnPropertyNames(newData));
      for (i = 0; i < keys.length; i++) {
        key = keys[i];
        if (typeof oldData[key] === "object" || typeof newData[key] === "object") {
          continue;
        }
        if (oldData[key] !== newData[key]) {
          if (oldDiff.attr === undefined) {
            oldDiff.attr = {data: {}};
            newDiff.attr = {data: {}};
          }
          oldDiff.attr.data[key] = oldData[key];
          newDiff.attr.data[key] = newData[key];
          isDifferent = true;
        }
      }
    }
    if (diffTypes.softParams) {
      keys = ["collapsed", "position"];
      for (i = 0; i < keys.length; i++) {
        key = keys[i];
        if (oldIdea.attr[key] !== newIdea.attr[key]) {
          if (oldDiff.attr === undefined) {
            oldDiff.attr = {};
            newDiff.attr = {};
          }
          oldDiff.attr[key] = oldIdea.attr[key];
          newDiff.attr[key] = newIdea.attr[key];
          isDifferent = true;
        }
      }
    }
    if (_.isEmpty(oldIdea.ideas) && !_.isEmpty(newIdea.ideas)) {
      newDiff.ideas = newIdea.ideas;
      isDifferent = true;
    } else if (_.isEmpty(newIdea.ideas) && !_.isEmpty(oldIdea.ideas)) {
      oldDiff.ideas = oldIdea.ideas;
      isDifferent = true;
    } else {
      var oldIdeas = $.extend({}, oldIdea.ideas);
      var newIdeas = $.extend({}, newIdea.ideas);
      var oldKeys = Object.getOwnPropertyNames(oldIdeas);
      var newKeys = Object.getOwnPropertyNames(newIdeas);
      for (var j = 0; j < oldKeys.length; j++) {
        var oldKey = oldKeys[j];
        var oldSubIdea = oldIdea.ideas[oldKey];
        var oldSubIdeaId = this.ysy.getData(oldSubIdea).id;
        for (var k = 0; k < newKeys.length; k++) {
          var newKey = newKeys[k];
          if (!newIdeas.hasOwnProperty(newKey)) continue;
          var newSubIdea = newIdea.ideas[newKey];
          var newSubIdeaId = this.ysy.getData(newSubIdea).id;
          if (oldSubIdeaId !== newSubIdeaId) continue;
          var diff = recursiveDiff(oldSubIdea, newSubIdea, diffTypes);
          if (diff && diff.oldDiff) {
            if (oldDiff.ideas === undefined) {
              oldDiff.ideas = {};
            }
            oldDiff.ideas[oldKey] = diff.oldDiff;
            isDifferent = true;
          }
          if (diff && diff.newDiff) {
            if (newDiff.ideas === undefined) {
              newDiff.ideas = {};
            }
            newDiff.ideas[newKey] = diff.newDiff;
            isDifferent = true;
          }
          delete oldIdeas[oldKey];
          delete newIdeas[newKey];
        }
        if (oldIdeas[oldKey]) {
          if (!oldDiff.ideas) oldDiff.ideas = {};
          oldDiff.ideas[oldKey] = oldIdeas[oldKey];
          isDifferent = true;
        }
      }
      for (newKey in newIdeas) {
        if (!newIdeas.hasOwnProperty(newKey)) continue;
        if (!newDiff.ideas) newDiff.ideas = {};
        newDiff.ideas[newKey] = newIdeas[newKey];
        isDifferent = true;
      }
    }
    if (!isDifferent) return null;
    var ret = {};
    if (!_.isEmpty(oldDiff)) ret.oldDiff = oldDiff;
    if (!_.isEmpty(newDiff)) ret.newDiff = newDiff;
    return ret;
  };
//######################################################################################
  /**
   *
   * @param {Storage} storage
   * @property {MindMup} ysy
   * @constructor
   */
  function StorageSettings(storage) {
    this.storage = storage;
    this.ysy = storage.ysy;
    this.init(storage.ysy);
  }

  StorageSettings.prototype._key = "settings";
  /**
   * @param {MindMup} ysy
   */
  StorageSettings.prototype.init = function (ysy) {
    var self = this;
    ysy.eventBus.register("saveOneSideOn",function(targetState){
      self.saveOneSide(targetState);
    });
    ysy.eventBus.register("nodeStyleChanged", function () {
      self.saveStyle();
    });
    ysy.eventBus.register("legendToggled", function (opened) {
      self._save({legendHidden: !opened}, false, null);
    });
    ysy.eventBus.register("legendHeaderToggled", function (hidden) {
      self._save({legendHeaderHidden: hidden}, false, null);
    });
    ysy.eventBus.register("BeforeServerClassInit",function () {
      self.load();
    });
  };
  StorageSettings.prototype.load = function () {
    this.ysy.settings.oneSideOn = this._load("oneSideOn", null);
    this.ysy.toolbar.redraw("toggleOneSide");
  };
  StorageSettings.prototype.loadStyle = function () {
    return this._load("defaultStyle", this.ysy.settings.rootID);
  };
  StorageSettings.prototype.loadLegendHidden = function () {
    return this._load("legendHidden", null);
  };
  StorageSettings.prototype.loadLegendHeaderHidden = function () {
    return this._load("legendHeaderHidden", null);
  };
  /**
   *
   * @param {String|Array.<String>} keys
   * @param {String|null} rootKey
   * @private
   */
  StorageSettings.prototype._load = function (keys, rootKey) {
    if (!rootKey) {
      rootKey = this._key;
    } else {
      rootKey = this._key + '-' + rootKey;
    }
    var extractString = this.storage.getPersistentData(rootKey);
    if (!extractString) return;
    var extract = JSON.parse(extractString);
    if (typeof keys === "string") {
      return extract[keys];
    }
    return _.pick(extract, keys);
  };
  /**
   * @param {boolean} oneSideOn
   */
  StorageSettings.prototype.saveOneSide = function (oneSideOn) {
    this._save({oneSideOn: oneSideOn}, false, null);
  };
  StorageSettings.prototype.saveStyle = function () {
    var stylesClass = this.ysy.styles;
    this._save(
        {defaultStyle: stylesClass.setting === stylesClass.defaultStyle ? undefined : stylesClass.setting},
        false,
        this.ysy.settings.rootID
    );
  };
  /**
   * @param {Object} map
   * @param {boolean} keepFalse
   * @param {(string|null)} rootKey
   * @param {boolean} [map.oneSideOn]
   * @param {String} [map.defaultStyle]
   * @param {boolean} [map.legendToggle]
   */
  StorageSettings.prototype._save = function (map, keepFalse, rootKey) {
    if (!rootKey) {
      rootKey = this._key;
    } else {
      rootKey = this._key + '-' + rootKey;
    }
    var extractString = this.storage.getPersistentData(rootKey);
    if (!extractString) {
      var updatedExtract = {};
    } else {
      var extract = JSON.parse(extractString);
      updatedExtract = _.clone(extract);
    }
    var updatingKeys = _.keys(map);
    if (keepFalse) {
      for (var i = 0; i < updatingKeys.length; i++) {
        var key = updatingKeys[i];
        if (map[key] === undefined) {
          delete updatedExtract[key];
        } else {
          updatedExtract[key] = map[key];
        }
      }
    } else {
      for (i = 0; i < updatingKeys.length; i++) {
        key = updatingKeys[i];
        if (!map[key]) {
          delete updatedExtract[key];
        } else {
          updatedExtract[key] = map[key];
        }
      }
    }
    if (_.isEqual(extract, updatedExtract)) return;
    if (_.isEmpty(updatedExtract)) {
      this.storage.resetPersistentData(rootKey);
      return;
    }
    this.storage.savePersistentData(rootKey, JSON.stringify(updatedExtract));
  };
})();
