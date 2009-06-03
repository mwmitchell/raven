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
package org.apache.solr.handler.extraction;


/**
 * The various Solr Parameters names to use when extracting content.
 *
 **/
public interface ExtractingParams {

  public static final String EXTRACTING_PREFIX = "ext.";

  /**
   * The param prefix for mapping Tika metadata to Solr fields.
   * <p/>
   * To map a field, add a name like:
   * <pre>ext.map.title=solr.title</pre>
   *
   * In this example, the tika "title" metadata value will be added to a Solr field named "solr.title"
   *
   *
   */
  public static final String MAP_PREFIX = EXTRACTING_PREFIX + "map.";

  /**
   * The boost value for the name of the field.  The boost can be specified by a name mapping.
   * <p/>
   * For example
   * <pre>
   * ext.map.title=solr.title
   * ext.boost.solr.title=2.5
   * </pre>
   * will boost the solr.title field for this document by 2.5
   *
   */
  public static final String BOOST_PREFIX = EXTRACTING_PREFIX + "boost.";

  /**
   * Pass in literal values to be added to the document, as in
   * <pre>
   *  ext.literal.myField=Foo 
   * </pre>
   *
   */
  public static final String LITERALS_PREFIX = EXTRACTING_PREFIX + "literal.";


  /**
   * Restrict the extracted parts of a document to be indexed
   *  by passing in an XPath expression.  All content that satisfies the XPath expr.
   * will be passed to the {@link SolrContentHandler}.
   * <p/>
   * See Tika's docs for what the extracted document looks like.
   * <p/>
   * @see #DEFAULT_FIELDNAME
   * @see #CAPTURE_FIELDS
   */
  public static final String XPATH_EXPRESSION = EXTRACTING_PREFIX + "xpath";


  /**
   * Only extract and return the document, do not index it.
   */
  public static final String EXTRACT_ONLY = EXTRACTING_PREFIX + "extract.only";

  /**
    *  Don't throw an exception if a field doesn't exist, just ignore it
   */
  public static final String IGNORE_UNDECLARED_FIELDS = EXTRACTING_PREFIX + "ignore.und.fl";

  /**
   * Index attributes separately according to their name, instead of just adding them to the string buffer
   */
  public static final String INDEX_ATTRIBUTES = EXTRACTING_PREFIX + "idx.attr";

  /**
   * The field to index the contents to by default.  If you want to capture a specific piece
   * of the Tika document separately, see {@link #CAPTURE_FIELDS}.
   *
   * @see #CAPTURE_FIELDS
   */
  public static final String DEFAULT_FIELDNAME = EXTRACTING_PREFIX + "def.fl";

  /**
   * Capture the specified fields (and everything included below it that isn't capture by some other capture field) separately from the default.  This is different
   * then the case of passing in an XPath expression.
   * <p/>
   * The Capture field is based on the localName returned to the {@link SolrContentHandler}
   * by Tika, not to be confused by the mapped field.  The field name can then
   * be mapped into the index schema.
   * <p/>
   * For instance, a Tika document may look like:
   * <pre>
   *  &lt;html&gt;
   *    ...
   *    &lt;body&gt;
   *      &lt;p&gt;some text here.  &lt;div&gt;more text&lt;/div&gt;&lt;/p&gt;
   *      Some more text
   *    &lt;/body&gt;
   * </pre>
   * By passing in the p tag, you could capture all P tags separately from the rest of the text.
   * Thus, in the example, the capture of the P tag would be: "some text here.  more text"
   *
   * @see #DEFAULT_FIELDNAME
   */
  public static final String CAPTURE_FIELDS = EXTRACTING_PREFIX + "capture";

  /**
   * The type of the stream.  If not specified, Tika will use mime type detection.
   */
  public static final String STREAM_TYPE = EXTRACTING_PREFIX + "stream.type";


  /**
   * Optional.  The file name. If specified, Tika can take this into account while
   * guessing the MIME type.
   */
  public static final String RESOURCE_NAME = EXTRACTING_PREFIX + "resource.name";


  /**
   * Optional.  If specified, the prefix will be prepended to all Metadata, such that it would be possible
   * to setup a dynamic field to automatically capture it
   */
  public static final String METADATA_PREFIX = EXTRACTING_PREFIX + "metadata.prefix";
}
