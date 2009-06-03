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

package org.apache.solr.search;

import org.apache.lucene.index.Term;
import org.apache.lucene.queryParser.ParseException;
import org.apache.lucene.queryParser.QueryParser;
import org.apache.lucene.search.*;
import org.apache.lucene.analysis.Analyzer;
import org.apache.solr.common.SolrException;
import org.apache.solr.schema.FieldType;
import org.apache.solr.schema.IndexSchema;
import org.apache.solr.schema.TrieField;

// TODO: implement the analysis of simple fields with
// FieldType.toInternal() instead of going through the
// analyzer.  Should lead to faster query parsing.

/**
 * A variation on the Lucene QueryParser which knows about the field 
 * types and query time analyzers configured in Solr's schema.xml.
 *
 * <p>
 * This class also deviates from the Lucene QueryParser by using 
 * ConstantScore versions of RangeQuery and PrefixQuery to prevent 
 * TooManyClauses exceptions.
 * </p> 
 *
 * <p>
 * If the magic field name "<code>_val_</code>" is used in a term or 
 * phrase query, the value is parsed as a function.
 * </p>
 *
 * @see QueryParsing#parseFunction
 * @see ConstantScoreRangeQuery
 * @see ConstantScorePrefixQuery
 */
public class SolrQueryParser extends QueryParser {
  protected final IndexSchema schema;
  protected final QParser parser;
  protected final String defaultField;

  /**
   * Constructs a SolrQueryParser using the schema to understand the
   * formats and datatypes of each field.  Only the defaultSearchField
   * will be used from the IndexSchema (unless overridden),
   * &lt;solrQueryParser&gt; will not be used.
   * 
   * @param schema Used for default search field name if defaultField is null and field information is used for analysis
   * @param defaultField default field used for unspecified search terms.  if null, the schema default field is used
   * @see IndexSchema#getSolrQueryParser(String defaultField)
   */
  public SolrQueryParser(IndexSchema schema, String defaultField) {
    super(defaultField == null ? schema.getDefaultSearchFieldName() : defaultField, schema.getQueryAnalyzer());
    this.schema = schema;
    this.parser  = null;
    this.defaultField = defaultField;
    setLowercaseExpandedTerms(false);
    setEnablePositionIncrements(true);    
  }

  public SolrQueryParser(QParser parser, String defaultField) {
    this(parser, defaultField, parser.getReq().getSchema().getQueryAnalyzer());
  }

  public SolrQueryParser(QParser parser, String defaultField, Analyzer analyzer) {
    super(defaultField, analyzer);
    this.schema = parser.getReq().getSchema();
    this.parser = parser;
    this.defaultField = defaultField;
    setLowercaseExpandedTerms(false);
    setEnablePositionIncrements(true);
  }

  private void checkNullField(String field) throws SolrException {
    if (field == null && defaultField == null) {
      throw new SolrException
        (SolrException.ErrorCode.BAD_REQUEST,
         "no field name specified in query and no defaultSearchField defined in schema.xml");
    }
  }

  protected Query getFieldQuery(String field, String queryText) throws ParseException {
    checkNullField(field);
    // intercept magic field name of "_" to use as a hook for our
    // own functions.
    if (field.charAt(0) == '_') {
      if ("_val_".equals(field)) {
        if (parser==null) {
          return QueryParsing.parseFunction(queryText, schema);
        } else {
          QParser nested = parser.subQuery(queryText, "func");
          return nested.getQuery();
        }
      } else if ("_query_".equals(field) && parser != null) {
        return parser.subQuery(queryText, null).getQuery();
      }
    }

    // default to a normal field query
    return super.getFieldQuery(field, queryText);
  }

  protected Query getRangeQuery(String field, String part1, String part2, boolean inclusive) throws ParseException {
    checkNullField(field);
    FieldType ft = schema.getFieldType(field);
    return ft.getRangeQuery(parser, field,
            "*".equals(part1) ? null : part1,
            "*".equals(part2) ? null : part2,
            inclusive, inclusive);
  }

  protected Query getPrefixQuery(String field, String termStr) throws ParseException {
    checkNullField(field);
    if (getLowercaseExpandedTerms()) {
      termStr = termStr.toLowerCase();
    }

    // TODO: toInternal() won't necessarily work on partial
    // values, so it looks like we need a getPrefix() function
    // on fieldtype?  Or at the minimum, a method on fieldType
    // that can tell me if I should lowercase or not...
    // Schema could tell if lowercase filter is in the chain,
    // but a more sure way would be to run something through
    // the first time and check if it got lowercased.

    // TODO: throw exception if field type doesn't support prefixes?
    // (sortable numeric types don't do prefixes, but can do range queries)
    Term t = new Term(field, termStr);
    return new ConstantScorePrefixQuery(t);
  }

  protected Query getWildcardQuery(String field, String termStr) throws ParseException {
    Query q = super.getWildcardQuery(field, termStr);
    if (q instanceof WildcardQuery) {
      // use a constant score query to avoid overflowing clauses
      return new ConstantScoreQuery(new WildcardFilter(((WildcardQuery)q).getTerm()));
    }
    return q;
  }
}
