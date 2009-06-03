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

package org.apache.solr.spelling;

import java.io.IOException;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.lucene.analysis.Token;
import org.apache.lucene.analysis.TokenStream;


/**
 * Converts the query string to a Collection of Lucene tokens using a regular expression.
 * Boolean operators AND and OR are skipped.
 *
 * @since solr 1.3
 **/
public class SpellingQueryConverter extends QueryConverter  {

  protected Pattern QUERY_REGEX = Pattern.compile("(?:(?!(\\w+:|\\d+)))\\w+");

  /**
   * Converts the original query string to a collection of Lucene Tokens.
   * @param original the original query string
   * @return a Collection of Lucene Tokens
   */
  public Collection<Token> convert(String original) {
    if (original == null) { // this can happen with q.alt = and no query
      return Collections.emptyList();
    }
    Collection<Token> result = new ArrayList<Token>();
    //TODO: Extract the words using a simple regex, but not query stuff, and then analyze them to produce the token stream
    Matcher matcher = QUERY_REGEX.matcher(original);
    TokenStream stream;
    while (matcher.find()) {
      String word = matcher.group(0);
      if (word.equals("AND") == false && word.equals("OR") == false) {
        try {
          stream = analyzer.reusableTokenStream("", new StringReader(word));
          Token token;
          while ((token = stream.next()) != null) {
            token.setStartOffset(matcher.start());
            token.setEndOffset(matcher.end());
            result.add(token);
          }
        } catch (IOException e) {
        }
      }
    }
    return result;
  }

}

