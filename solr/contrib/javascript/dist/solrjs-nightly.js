/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @namespace A unique namespace inside jQuery.
 */
jQuery.solrjs = function() {};


/** 
 * A static "constructor" method that creates widget classes.
 *
 * <p> It uses manual jquery inheritance inspired by 
 * http://groups.google.com/group/jquery-dev/msg/12d01b62c2f30671' </p>
 * 
 * @param baseClass The name of the parent class. Set null to create a top level class. 
 * @param subClass The fields and methods of the new class.
 * @returns A constructor method that represents the new class. 
 * 
 * @example
 *   jQuery.solrjs.MyClass = jQuery.solrjs.createClass ("MyBaseClass", {
 *      property1: "value",
 *      function1: function() { alert("Hello World") }
 *   });
 *
 * 
 */
jQuery.solrjs.createClass = function(baseClassName, subClass) {
		
	// create new class, adding the constructor 
  var newClass = jQuery.extend(true, subClass , {	

		constructor : function(options) {
			// if a baseclass is specified, inherit methods and props, and store it in _super_			
			if (baseClassName != null) { 
	    	jQuery.extend(true, this, new jQuery.solrjs[baseClassName](options) );
			}
			// add new methods and props for this class
		  jQuery.extend(true, this , subClass);
      // add constructor arguments	    
			jQuery.extend(true, this, options); 
  	}
	});
	
	// make new class accessible
	return newClass.constructor;

};
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Represents a query item (search term). It consists of a fieldName and a value. .
 * 
 * @param properties A map of fields to set. Refer to the list of non-private fields.
 * @class QueryItem
 */
jQuery.solrjs.QueryItem = jQuery.solrjs.createClass (null, /** @lends jQuery.solrjs.QueryItem.prototype */  { 
    
  /** 
   * the field name.
   * @field 
   * @public
   */
  field : "",  
   
  /** 
   * The value
   * @field 
   * @public
   */
  value : "",  
    
  /**
   * creates a lucene query syntax, eg pet:"Cats"
   */  
  toSolrQuery: function() {
		return "(" + this.field + ":\"" + this.value + "\")";
  },
  
  /**
   * Uses fieldName and value to compare items.
   */
  equals: function(obj1, obj2) {
  	if (obj1.field == obj2.field && obj1.value == obj2.value) {
  		return true;
  	}
  	return false;
  }
    
});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * The "Manager" acts as a container for all widgets. 
 *
 * <p> It stores solr configuration and selection and delegates calls to the widgets.
 *     All public calls should be performed on the manager object. </p>
 * <p> There has to be exactly one instance called "solrjsManager" present </p> 
 *     
 *
 * @example
 *  var solrjsManager;
 *   $sj(document).ready(function(){
 *       solrjsManager = new $sj.solrjs.Manager(
 *         { solrUrl:"http://localhost:8983/solr/select", 
 *           resourcesBase: "../../src/resources" });
 *   });
 *
 * @param properties A map of fields to set. Refer to the list of non-private fields.
 * @class Manager
 */
jQuery.solrjs.Manager = jQuery.solrjs.createClass (null,  /** @lends jQuery.solrjs.Manager.prototype */ {

  /** 
   * The absolute url to the solr instance
   * @field 
   * @default http://localhost:8983/solr/select/
   * @public
   */
   solrUrl : "http://localhost:8983/solr/select/",
   
  /** 
   * A path (absolute or relative) to the base directory of solrjs resources (css, imgs,..)
   * @field 
   * @public
   */
   resourcesBase : "",

  /** 
   * A constant representing "all documents"
   * @field 
   * @private 
   */
  QUERY_ALL : "*:*",  
  
  /** 
   * A collection of all registered widgets. For internal use only. 
   * @field 
   * @private 
   */
  widgets : [],
  
  /** 
   * A collection of the currently selected QueryItems. For internal use only. 
   * @field 
   * @private 
   */
  queryItems : [],
  
  /** 
   * A collection of the attached selection views. 
   * @field 
   * @private 
   */
  selectionViews : [],

 /** 
   * Adds a widget to this manager. 
   * @param {jQuery.solrjs.AbstractWidget} widget An instance of AbstractWidget. 
   */
  addWidget : function(widget) { 
		widget.manager = this;
 	  this.widgets[widget.id] = widget;
 	  widget.afterAdditionToManager();
	},
	
 /** 
   * Adds a selection view to this manager. 
   * @param {jQuery.solrjs.AbstractSelectionView} widget An instance of AbstractSelectionView. 
   */
  addSelectionView : function(view) { 
    view.manager = this;
    this.selectionViews[view.id] = view;
  },

  /** 
   * Adds the given items to the current selection.
   * @param widgetId The widgetId of where these items were selected. 
   * @param items A list of newly selected items. 
   */
	selectItems: function(widgetId, items){
  	this.widgets[widgetId].select(items);
  	var querySizeBefore = this.queryItems.length;
  	for (var i = 0; i < items.length; ++i) {
      if (!this.containsItem(items[i])) {
        this.queryItems.push(items[i]);
      }
    }
    if (querySizeBefore < this.queryItems.length) {
      this.doRequest(0);
    }
  },
  
  /** 
   * Removes the given items from the current selection.
   * @param widgetId The widgetId of where these items were deselected. 
   */  
  deselectItems: function(widgetId){
  	var widget = this.widgets[widgetId];
  	for (var i = 0; i < widget.selectedItems.length; i++) {
      for (var j = 0; j < this.queryItems.length; j++) {
        if (this.queryItems[j].toSolrQuery() ==  widget.selectedItems[i].toSolrQuery()) {
          this.queryItems.splice(j, 1);
        }   
      }
    }     
  	widget.deselect();
  	this.doRequest(0);
  },
  
  /** 
   * Removes the given item from the current selection, regardless of widgets.
   * @param widgetId The widgetId of where these items were deselected. 
   */  
  deselectItem: function(solrQuery){
    for (var j = 0; j < this.queryItems.length; j++) {
      var s = this.queryItems[j].toSolrQuery();
      if (s ==  solrQuery) {
        this.queryItems.splice(j, 1);
      }   
    }
    this.doRequest(0);
  },
    
  /** 
   * Checks if the given item is available in the current selection.
   * @param {jQuery.solrjs.QueryItem} item The item to check.
   */  
  containsItem: function(item){
  	for (var i = 0; i < this.queryItems.length; ++i) {
  		if (this.queryItems[i].toSolrQuery() == item.toSolrQuery()) {
  			return true;
  		}		
  	}
  	return false;
  },
  
  /** 
   * Creates a query out of the current selection and calls all bound widgets to
   * request their data from the server.
   * @param start The solr start offset parameter (mostly for result widgets).
   * @param resultsOnly Indicates that only the page changed and only result widgets should repaint).
   */ 
  doRequest : function(start, resultsOnly) { 
		var query = "";
    	
  	if (this.queryItems.length == 0) {
  		query = this.QUERY_ALL;
  	} else {
  		for (var i = 0; i < this.queryItems.length; ++i) {
  			query += this.queryItems[i].toSolrQuery();
  			if (i < this.queryItems.length -1) {
  				query += " AND ";
  			}
  		}
  	}

	  for (var id in this.widgets) {
	  	this.widgets[id].doRequest(query, start, resultsOnly);
	  }
	  
	  for (var id in this.selectionViews) {
      this.selectionViews[id].displaySelection(this.queryItems);
    }
	}, 

  /** 
   * Sets the current selection to *:* and requests all docs.
   */ 
	doRequestAll: function() {
    this.queryItems=[];
    this.doRequest(0);   
  },
  
  clearSelection: function() {
    this.queryItems=[];
  },
  
  /** 
   * Helper method that returns an ajax-loading.gif inside a div.
   */ 
  getLoadingDiv : function() {
    var div = jQuery("<div/>");
    jQuery("<img/>").attr("src", this.resourcesBase + "/img/ajax-loader.gif" ).appendTo(div);
    return div;
  }
});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Baseclass for all widgets. 
 * 
 * <p> Handles selection and request of items (called by the manager) and provides 
 *     abstract hooks for child classes to display the data.  </p>
 *
 * @param properties A map of fields to set. Refer to the list of non-private fields.  
 * @class AbstractWidget
 */
jQuery.solrjs.AbstractWidget = jQuery.solrjs.createClass (null, /** @lends jQuery.solrjs.AbstractWidget.prototype */ { 

  /** 
   * A unique identifier of this widget.
   *
   * @field 
   * @public
   */
  id : "", 

  /** 
   * The number of documents this widgets requests.
   * Normally only useful for result widgets.
   *
   * @field 
   * @default 0
   * @public
   */
	rows : 0, 
	
	/** 
   * A private flag that displays the selection status of a widget.
   * Selected widgets normally don't need to update their data when 
   * the selection changes.
   * 
   * @field 
   * @private
   */
	selected : false,
	
	/** 
   * A css classname representing the "target div" inside the html page.
   * All ui changes will be performed inside this empty div.
   * 
   * @field 
   * @private
   */
  target : "",
  
  /** 
   * A flag for result widgets. These widgets also get updated on page changes,
   * 
   * @field 
   * @private
   */
  isResult : false,
  
  /** 
   * A flag that indicates whether the loading icon should be displayed.
   * 
   * @field 
   * @private
   */
  showLoadingDiv : false,
  
  /** 
   * A flag that indicates whether the widget should save the current selection. If set to false,
   * a widget may be selected more than once.
   * 
   * @field 
   * @private
   */
  saveSelection : false,

  /**
   * Generates the solr request url for this widget and delegates the actual request
   * to the implementation. This method is only called by the manager.
   * 
   * @param query The current solr query
   * @start The offset.
   * @param resultsOnly Indicates that only the page changed and only result widgets should repaint).
   */
  doRequest : function(query, start, resultsOnly) { 
  	if (resultsOnly && !this.isResult) {
      return;
    }   
  	if (this.saveSelection && this.selected) {
			return;
		}    
		var solrRequestUrl = "";
		solrRequestUrl += this.manager.solrUrl;
		solrRequestUrl += "?";		
		solrRequestUrl += "&rows=" + this.rows;		
    solrRequestUrl += "&start=" + start;				
		solrRequestUrl += "&q=" + query;		
		solrRequestUrl += this.getSolrUrl(start);	

		// show loading gif
		if (this.showLoadingDiv) {
		  jQuery(this.target).html(this.manager.getLoadingDiv());
		}
		
		// let the implementation execute the call
		this.executeHttpRequest(solrRequestUrl);
		
	},

  /**
   * Marks this widget as selected and store selected items.
   * This method is only called by the manager.
   *
   * @param items The list of newly selected items.
   */
  select: function(items) {
  	if (this.saveSelection) {
    	this.selected = true;
  		this.selectedItems = items;
  	}
	  this.handleSelect();  	
  },
    
  /**
   * Marks this widget as unselected and clears the selected items.
   * This method is only called by the manager.
   */  
  deselect: function() {
    if (this.saveSelection) {
      this.selected = false;
    }  
    this.handleDeselect();
  },


	// Methods to be overridden by widgets:

  /**
   * An abstract hook for child implementations. This method should
   * execute the http request.
   * @param the complete solr request url.
   * @abstract 
   */
  executeHttpRequest : function(url) { 
		throw "Abstract method executeHttpRequest"; 
	},

  /** 
   * An abstract hook for child implementations. It should add widget specific
   * request parameters like facet=true..
   * @param start The offset.
   */
  getSolrUrl : function(start) { 
		// to be overridden
		return ""; 
	},

  /** 
   * An abstract hook for child implementations. Called after a widget is selected.
   * Child implementations should take care of changing the ui. 
   */
  handleSelect : function() { 
		// do nothing. Implementations may place some handler code here. 
	},

  /** 
   * An abstract hook for child implementations. Called after a widget is deselected.
   * Child implementations should take care of changing the ui. 
   */
	handleDeselect : function() { 
		// do nothing Implementations may place some handler code here. 
	},
	
	afterAdditionToManager : function() { 
    // do nothing by default. Implementations may place some init code here. 
  }
});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Baseclass for server side widgets.
 * 
 * <p> The velocity response writer is used, the widget only specifies the
 *     template name in the getTemplateName() method. </p>
 *
 * @param properties A map of fields to set. Refer to the list of non-private fields. 
 * @class AbstractServerSideWidget
 * @augments jQuery.solrjs.AbstractWidget
 */
jQuery.solrjs.AbstractServerSideWidget = jQuery.solrjs.createClass ("AbstractWidget", /** @lends jQuery.solrjs.AbstractServerSideWidget.prototype */  { 
  
  /**
   * Adds the velocity specific request parameters to the url and creates a JSON call
   * using a dynamic script tag. The html response from the velocity template gets wrapped inside a 
   * javascript object to make cross site requests possible.
   * 
   * @param url The solr query request
   */
  executeHttpRequest : function(url) { 
    url += "&wt=velocity&v.response=QueryResponse&v.json=?&jsoncallback=?&v.contentType=text/json&v.template=" + this.getTemplateName();
    url += "&solrjs.widgetid=" + this.id;   
    var me = this;
    jQuery.getJSON(url,
      function(data){
        me.handleResult(data.result);
      }
    );
  },
  
  getTemplateName : function() { 
   throw("Abstract method");
  },
  
  /**
   * The default behaviour is that the result of teh template is simply "copied" to the target div.
   * 
   * @param result The result of the velocity template wrapped inside a javascript object.
   */
  handleResult : function(result) { 
    jQuery(this.target).html(result);
  },

});

/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Baseclass for client side widgets. 
 *
 * <p> The json response writer is used, the widget gets the result object passed
 *     to the handleResult() method
 * </p>
 * 
 * @param properties A map of fields to set. Refer to the list of non-private fields. 
 * @class AbstractClientSideWidget
 * @augments jQuery.solrjs.AbstractWidget
 */
jQuery.solrjs.AbstractClientSideWidget = jQuery.solrjs.createClass ("AbstractWidget", /** @lends jQuery.solrjs.AbstractClientSideWidget.prototype */ { 
  
  /**
   * Adds the JSON specific request parameters to the url and creates a JSON call
   * using a dynamic script tag.
   * @param url The solr query request
   */
  executeHttpRequest : function(url) { 
  	url += "&wt=json&json.wrf=?&jsoncallback=?";  
    var me = this;
  	jQuery.getJSON(url,
  	  function(data){
  		me.handleResult(data);    
  	  }
  	);
  }, 
  
  /**
   * An abstract hook for child implementations. It is a callback that
   * is execute after the solr response data arrived.
   * @param data The solr response inside a javascript object.
   */
  handleResult : function(data) { 
	 throw "Abstract method handleResult"; 
  }

});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Simple server side facet widget. Uses template "facets".
 * @class FacetServerSideWidget
 * @augments jQuery.solrjs.AbstractServerSideWidget
 */
jQuery.solrjs.FacetServerSideWidget = jQuery.solrjs.createClass ("AbstractServerSideWidget", /** @lends jQuery.solrjs.FacetServerSideWidget.prototype */ { 

  saveSelection : true,

  getSolrUrl : function(start) { 
    return "&facet=true&facet.field=" + this.fieldName;
  },

  getTemplateName : function() { 
  	return "facets"; 
  },  

  handleSelect : function(data) { 
	  jQuery(this.target).html(this.selectedItems[0].value);
    jQuery('<a/>').html("(x)").attr("href","javascript:solrjsManager.deselectItems('" + this.id + "')").appendTo(this.target);
  },

  handleDeselect : function(data) { 
    // do nothing, just refresh the view
  }	   

});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Simple server side widget, only gets a template.
 * 
 * @class SimpleServerSideWidget
 * @augments jQuery.solrjs.AbstractServerSideWidget
 */
jQuery.solrjs.SimpleServerSideWidget = jQuery.solrjs.createClass ("AbstractServerSideWidget", /** @lends jQuery.solrjs.SimpleServerSideWidget.prototype */{ 

  /** 
   * The name of the velocity template (without ".vm") to use.
   * @field 
   * @public
   */
   templateName : "",
   
  getTemplateName : function() { 
    return this.templateName; 
  }

});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * <p> Autocomplete input filed that suggests facet values. It can show facet values of multiple 
 * fields (specified by "fieldNames"), as well as perform a fulltext query ("fulltextFieldName")
 * in case no suggested value is selected. </p>
 *
 * It uses the autocomplete box found at http://docs.jquery.com/UI/Autocomplete/autocomplete.
 * 
 * @class AutocompleteWidget
 * @augments jQuery.solrjs.AbstractClientSideWidget
 */
jQuery.solrjs.AutocompleteWidget = jQuery.solrjs.createClass ("AbstractClientSideWidget", /** @lends jQuery.solrjs.AutocompleteWidget.prototype */{ 

  /** 
   * A list of facet fields.
   * @field 
   * @public
   */
  fieldNames : [] ,  
  
  /** 
   * The field to search in if when no suggestion is selected.
   * @field 
   * @public
   */
  fulltextFieldName : "",  

  getSolrUrl : function(start) { 
    var ret = "&facet=true&facet.limit=-1";
    for (var j = 0; j < this.fieldNames.length; j++) {
      ret += "&facet.field=" + this.fieldNames[j];
    }
    return ret;
    
  },

  handleResult : function(data) { 
    
    // create new input field
    jQuery(this.target).empty();
    var input = jQuery('<input/>').attr("id", this.id + "_input").appendTo(this.target);
    
    // create autocomplete list
    var list = [];
    for (var j = 0; j < this.fieldNames.length; j++) {
      var field = this.fieldNames[j];
      var values = data.facet_counts.facet_fields[field];  
      for (var i = 0; i < values.length; i = i + 2) {
        var label = values[i] + " (" + values[i+1] + ") - " + field;      
        var value = values[i];
        list.push({text:label, value:value, field:field});
      }
    }
    
    // add selection listeners for suggests and fulltext search.
    var me = this;
    me.selectionMade = false;
    input.autocomplete(list, {
      formatItem: function(item) {
        return item.text;
      }
    }).result(function(event, item) {
      var items =  [new jQuery.solrjs.QueryItem({field: item.field , value:item.value})];
      solrjsManager.selectItems(me.id, items);
      me.selectionMade = true;
    });
    jQuery("#" + this.id + "_input").html("test").bind("keydown", function(event) {
      if (me.selectionMade == false && event.keyCode==13) {
        var items =  [new jQuery.solrjs.QueryItem({field: me.fulltextFieldName , value:"\"" + event.target.value + "\""})];
        solrjsManager.selectItems(me.id, items);
      }
    });
  }

});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * A calenader facet field. it uses solr's date facet capabilities, and displays 
 * the document count of one day using the DHTML calendar from www.dynarch.com/projects/calendar
 * 
 * @class CalendarWidget
 * @augments jQuery.solrjs.AbstractClientSideWidget
 */
jQuery.solrjs.CalendarWidget = jQuery.solrjs.createClass ("AbstractClientSideWidget", { 

  /** 
   * Start date, used to restrict the calendar ui as well 
   * as the solr date facets.
   *
   * @field 
   * @public
   */
  startDate : null,
  
  /** 
   * Start date, used to restrict the calendar ui as well 
   * as the solr date facets.
   *
   * @field 
   * @public
   */
  endDate : null,  
  
  /** 
   * Current date facet array.
   *
   * @field 
   * @private
   */
  dates : null,  
  
  getSolrUrl : function(start) { 
    return "&facet=true&facet.mincount=1&facet.date=date&facet.date.start=1987-01-01T00:00:00.000Z/DAY&facet.date.end=1987-11-31T00:00:00.000Z/DAY%2B1DAY&facet.date.gap=%2B1DAY";
  },

  handleResult : function(data) { 
  
    var me = this;
    me.dates = [];
    jQuery.each(data.facet_counts.facet_dates.date, function(key, value) {
      var date = new Date(key.slice(0, 4), parseInt(key.slice(6, 8)) - 1, key.slice(8, 10));
      me.dates[date] = value;
    });
    
    jQuery(this.target).empty();
    
    var parent = document.getElementById("calendar");

    // construct a calendar giving only the "selected" handler.
    var cal = new Calendar(0, null, function (cal, date) {
      if (cal.dateClicked) {
        var dateString = "[" + date + "T00:00:00Z TO " + date + "T23:59:59Z]";
        var items =  [new jQuery.solrjs.QueryItem({field: me.fieldName , value:date, toSolrQuery: function() { return "date:" + dateString }})];
        solrjsManager.selectItems(me.id, items);
      }
    });
    cal.dateClicked = false;
    cal.weekNumbers = false;
    cal.setDateFormat("%Y-%m-%d");
    cal.setTtDateFormat("solrjs");
    
    cal.setDateStatusHandler(function(date) { 
        if (me.dates[date] != null && me.dates[date] > 0) {
          return "solrjs solrjs_value_" + me.dates[date];
        }
        return true;
      });
      
    cal.create(parent);
    cal.show();
    cal.setDate(new Date(1987, 2, 1));
    
    // override pribt method to display document count
    var oldPrint = Date.prototype.print;
    Date.prototype.print = function(string) {
      if (string.indexOf("solrjs") == -1) {
        return oldPrint.call(this, string);
      }
      return me.dates[this] + " documents found!";
    }
  }

});

/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Takes a solr field that stores an ISO-3166 country code. It creates facet values and
 * displays them in a selection dropdown as well as on a google chart map item. 
 * 
 * @class CountryCodeWidget
 * @augments jQuery.solrjs.AbstractClientSideWidget
 */
jQuery.solrjs.CountryCodeWidget = jQuery.solrjs.createClass ("AbstractClientSideWidget", { 

  /** 
   * The width of the map images.
   * 
   * @field 
   * @public
   */
  width : 350, 
  
  /** 
   * The height of the map images.
   *
   * @field 
   * @public
   */
  height : 180, 

  /** 
   * The field name of the iso country code field.
   *
   * @field 
   * @public
   */
  fieldName : "",  
  
  getSolrUrl : function(start) { 
		return "&facet=true&facet.mincount=1&facet.limit=-1&facet.field=" + this.fieldName;
  },

  handleResult : function(data) { 
	  jQuery(this.target).empty();
	  
	  // get facet counts
	  var values = data.facet_counts.facet_fields[this.fieldName];  
	  var maxCount = 0;
    var objectedItems = [];
    for (var i = 0; i < values.length; i = i + 2) {
      var c = parseInt(values[i+1]);
      if (c > maxCount) {
        maxCount = c;
      }
      objectedItems.push({label:values[i], count:values[i+1]});
    }
    
    // create a select for regions
    var container = jQuery("<div/>").attr("id",  "solrjs_" + this.id).appendTo(this.target);
    var select = jQuery("<select/>").appendTo(container);
    var me = this;
    select.change(function () {
      jQuery("#solrjs_" + me.id + " img").each(function (i,item) {
            jQuery(item).css("display", "none");
          });
      jQuery("#solrjs_" + me.id + this[this.selectedIndex].value).css("display", "block");
    });
    jQuery("<option/>").html("view the World ").attr("value", "world").appendTo(select);
    jQuery("<option/>").html("view Africa").attr("value", "africa").appendTo(select);
    jQuery("<option/>").html("view Asia").attr("value", "asia").appendTo(select);
    jQuery("<option/>").html("view Europe").attr("value", "europe").appendTo(select);
    jQuery("<option/>").html("view the Middle East").attr("value", "middle_east").appendTo(select);
    jQuery("<option/>").html("view South America").attr("value", "south_america").appendTo(select);
    jQuery("<option/>").html("view North America").attr("value", "usa").appendTo(select);
    
    // create a select for facet values
	  var codes = "";
	  var mapvalues = "t:";
	  var countrySelect = jQuery("<select/>").appendTo(container);
	  countrySelect.change(function () {
      var items =  [new jQuery.solrjs.QueryItem({field: me.fieldName , value:this[this.selectedIndex].value})];
      solrjsManager.selectItems(me.id, items);
    });
	  jQuery("<option/>").html("--select--").attr("value", "-1").appendTo(countrySelect);;
    
    // create map data
    for (var i = 0; i < objectedItems.length; i++) {
      if (objectedItems[i].label.length != 2) {
        continue;
      }
      codes += objectedItems[i].label;
      var currentValue = objectedItems[i].count;
      var percent =  (objectedItems[i].count / maxCount);
      var tagvalue = parseInt(percent * 100);       
      mapvalues += tagvalue + ".0";
      if (i < objectedItems.length - 1) {
        mapvalues += ",";
      }
      jQuery("<option/>").html(objectedItems[i].label + " (" + currentValue + ")").attr("value", objectedItems[i].label).appendTo(countrySelect);
    }
    
    // show maps
	  jQuery("<img/>").attr("id", "solrjs_" + this.id + "africa").css("display", "none").attr("src","http://chart.apis.google.com/chart?chco=f5f5f5,edf0d4,6c9642,365e24,13390a&chd=" + mapvalues + "&chf=bg,s,eaf7fe&chtm=africa&chld="+ codes +"&chs="+this.width+"x"+this.height+"&cht=t").appendTo(container);
	  jQuery("<img/>").attr("id", "solrjs_" + this.id + "asia").css("display", "none").attr("src","http://chart.apis.google.com/chart?chco=f5f5f5,edf0d4,6c9642,365e24,13390a&chd=" + mapvalues + "&chf=bg,s,eaf7fe&chtm=asia&chld="+ codes +"&chs="+this.width+"x"+this.height+"&cht=t").appendTo(container);
	  jQuery("<img/>").attr("id", "solrjs_" + this.id + "europe").css("display", "none").attr("src","http://chart.apis.google.com/chart?chco=f5f5f5,edf0d4,6c9642,365e24,13390a&chd=" + mapvalues + "&chf=bg,s,eaf7fe&chtm=europe&chld="+ codes +"&chs="+this.width+"x"+this.height+"&cht=t").appendTo(container);
	  jQuery("<img/>").attr("id", "solrjs_" + this.id + "middle_east").css("display", "none").attr("src","http://chart.apis.google.com/chart?chco=f5f5f5,edf0d4,6c9642,365e24,13390a&chd=" + mapvalues + "&chf=bg,s,eaf7fe&chtm=middle_east&chld="+ codes +"&chs="+this.width+"x"+this.height+"&cht=t").appendTo(container);
	  jQuery("<img/>").attr("id", "solrjs_" + this.id + "south_america").css("display", "none").attr("src","http://chart.apis.google.com/chart?chco=f5f5f5,edf0d4,6c9642,365e24,13390a&chd=" + mapvalues + "&chf=bg,s,eaf7fe&chtm=south_america&chld="+ codes +"&chs="+this.width+"x"+this.height+"&cht=t").appendTo(container);
	  jQuery("<img/>").attr("id", "solrjs_" + this.id + "usa").css("display", "none").attr("src","http://chart.apis.google.com/chart?chco=f5f5f5,edf0d4,6c9642,365e24,13390a&chd=" + mapvalues + "&chf=bg,s,eaf7fe&chtm=usa&chld="+ codes +"&chs="+this.width+"x"+this.height+"&cht=t").appendTo(container);
	  jQuery("<img/>").attr("id", "solrjs_" + this.id + "world").css("display", "block").attr("src","http://chart.apis.google.com/chart?chco=f5f5f5,edf0d4,6c9642,365e24,13390a&chd=" + mapvalues + "&chf=bg,s,eaf7fe&chtm=world&chld="+ codes +"&chs="+this.width+"x"+this.height+"&cht=t").appendTo(container);
	  
	  
	}
});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * A simple base class for result widgets (list of documents, including paging).
 * Implementations should override the renderResult(docs, pageSize, offset, numFound)
 * funtion to render the result.
 *
 * @class ExtensibleResultWidget
 * @augments jQuery.solrjs.AbstractClientSideWidget
 */
jQuery.solrjs.ExtensibleResultWidget = jQuery.solrjs.createClass ("AbstractClientSideWidget", { 
  
  isResult : true,
  
  getSolrUrl : function(start) { 
		return ""; // no special params need
	},

  handleResult : function(data) { 
    jQuery(this.target).empty();
    this.renderResult(data.response.docs, parseInt(data.responseHeader.params.rows), data.responseHeader.params.start, data.response.numFound);
	},

  renderResult : function(docs, pageSize, offset, numFound) { 
		throw "Abstract method renderDataItem";
  }
});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * A simple facet widteh that shows the facet values as list. It remembers the selection
 * and shows a "value(x)" label after selection.
 *
 * @class ExtensibleResultWidget
 * @augments jQuery.solrjs.AbstractClientSideWidget
 */
jQuery.solrjs.FacetWidget = jQuery.solrjs.createClass ("AbstractClientSideWidget", { 
  
  saveSelection : true,
  
  getSolrUrl : function(start) { 
		return "&facet=true&facet.field=" + this.fieldName;
  },

  handleResult : function(data) { 
	 var values = data.facet_counts.facet_fields[this.fieldName];	 
     jQuery(this.target).html("");
		
		for (var i = 0; i < values.length; i = i + 2) {
			var items =  "[new jQuery.solrjs.QueryItem({field:'" + this.fieldName + "',value:'" +  values[i] + "'})]";
      var label = values[i] + "(" + values[i+1] + ")";     	
			jQuery('<a/>').html(label).attr("href","javascript:solrjsManager.selectItems('" + this.id + "'," + items + ")").appendTo(this.target);
			jQuery('<br/>').appendTo(this.target);
		}
	},

	handleSelect : function(data) { 
		jQuery(this.target).html(this.selectedItems[0].value);
		jQuery('<a/>').html("(x)").attr("href","javascript:solrjsManager.deselectItems('" + this.id + "')").appendTo(this.target);
	},

	handleDeselect : function(data) { 
		// do nothing
	}	   
});
/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * A facet widget that renders the values as a tagcloud.
 *
 * @class TagcloudWidget
 * @augments jQuery.solrjs.AbstractClientSideWidget
 */
jQuery.solrjs.TagcloudWidget = jQuery.solrjs.createClass ("AbstractClientSideWidget", { 

  /** 
   * Maximum count of items in the tagcloud. 
   *
   * @field 
   * @public
   */
  size : 20,
  
  /** 
   * The facet field name.
   *
   * @field 
   * @public
   */
  fieldName : "",  
  
  getSolrUrl : function(start) { 
		return "&facet=true&facet.mincount=1&facet.field=" + this.fieldName + "&facet.limit=" + this.size;
  },

  handleResult : function(data) { 
	 var values = data.facet_counts.facet_fields[this.fieldName];	 
     jQuery(this.target).empty();
     
     if (values.length == 0) {
       jQuery("<div/>").html("not items found in current selection").appendTo(this.target);
     }
		
		 var maxCount = 0;
		 var objectedItems = [];
		 for (var i = 0; i < values.length; i = i + 2) {
		    var c = parseInt(values[i+1]);
		    if (c > maxCount) {
		      maxCount = c;
		    }
		    objectedItems.push({label:values[i], count:values[i+1]});
		 }
		 
		 objectedItems.sort(function(a,b) {
		   if (a.label < b.label) {
		    return -1;
		   }
		   return 1;  
		 });
		 
		 for (var i = 0; i < objectedItems.length; i++) {
       var label = objectedItems[i].label;
			 var items =  "[new jQuery.solrjs.QueryItem({field:'" + this.fieldName + "',value:'" +  label + "'})]";
       var percent =  (objectedItems[i].count / maxCount);
       var tagvalue = parseInt(percent * 10);     	
			 jQuery("<a/>").html(label).addClass("solrjs_tagcloud_item").addClass("solrjs_tagcloud_size_" + tagvalue).attr("href","javascript:solrjsManager.selectItems('" + this.id + "'," + items + ")").appendTo(this.target);
		 }
		 
		 jQuery("<div/>").addClass("solrjs_tagcloud_clearer").appendTo(this.target);
		 
	}
});
