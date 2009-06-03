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
package org.apache.solr.analysis;

import java.util.Map;
import java.util.List;
import java.io.File;
import java.io.IOException;

import org.apache.lucene.analysis.TokenStream;
import org.apache.lucene.analysis.CharArraySet;
import org.apache.lucene.analysis.TokenFilter;
import org.apache.lucene.analysis.Token;
import org.apache.lucene.analysis.snowball.SnowballFilter;
import org.apache.solr.common.ResourceLoader;
import org.apache.solr.common.util.StrUtils;
import org.apache.solr.util.plugin.ResourceLoaderAware;
import org.tartarus.snowball.SnowballProgram;

/**
 * Factory for SnowballFilters, with configurable language
 * 
 * Browsing the code, SnowballFilter uses reflection to adapt to Lucene... don't
 * use this if you are concerned about speed. Use EnglishPorterFilterFactory.
 * 
 * @version $Id: SnowballPorterFilterFactory.java 746122 2009-02-20 03:23:58Z ehatcher $
 */
public class SnowballPorterFilterFactory extends BaseTokenFilterFactory implements ResourceLoaderAware {
  public static final String PROTECTED_TOKENS = "protected";

  private String language = "English";
  private Class stemClass;


  public void inform(ResourceLoader loader) {
    String wordFiles = args.get(PROTECTED_TOKENS);
    if (wordFiles != null) {
      try {
        File protectedWordFiles = new File(wordFiles);
        if (protectedWordFiles.exists()) {
          List<String> wlist = loader.getLines(wordFiles);
          //This cast is safe in Lucene
          protectedWords = new CharArraySet(wlist, false);//No need to go through StopFilter as before, since it just uses a List internally
        } else  {
          List<String> files = StrUtils.splitFileNames(wordFiles);
          for (String file : files) {
            List<String> wlist = loader.getLines(file.trim());
            if (protectedWords == null)
              protectedWords = new CharArraySet(wlist, false);
            else
              protectedWords.addAll(wlist);
          }
        }
      } catch (IOException e) {
        throw new RuntimeException(e);
      }
    }
  }

  private CharArraySet protectedWords = null;

  @Override
  public void init(Map<String, String> args) {
    super.init(args);
    final String cfgLanguage = args.get("language");
    if(cfgLanguage!=null) language = cfgLanguage;

    try {
      stemClass = Class.forName("org.tartarus.snowball.ext." + language + "Stemmer");
    } catch (ClassNotFoundException e) {
      throw new RuntimeException("Can't find class for stemmer language " + language, e);
    }
  }
  
  public SnowballPorterFilter create(TokenStream input) {
    SnowballProgram program;
    try {
      program = (SnowballProgram)stemClass.newInstance();
    } catch (Exception e) {
      throw new RuntimeException("Error instantiating stemmer for language " + language + "from class " +stemClass, e);
    }
    return new SnowballPorterFilter(input, program, protectedWords);
  }
}

class SnowballPorterFilter extends TokenFilter {
  private final CharArraySet protWords;
  private SnowballProgram stemmer;

  public SnowballPorterFilter(TokenStream source, SnowballProgram stemmer, CharArraySet protWords) {
    super(source);
    this.protWords = protWords;
    this.stemmer = stemmer;
  }


  /**
   * the original code from lucene sandbox
   * public final Token next() throws IOException {
   * Token token = input.next();
   * if (token == null)
   * return null;
   * stemmer.setCurrent(token.termText());
   * try {
   * stemMethod.invoke(stemmer, EMPTY_ARGS);
   * } catch (Exception e) {
   * throw new RuntimeException(e.toString());
   * }
   * return new Token(stemmer.getCurrent(),
   * token.startOffset(), token.endOffset(), token.type());
   * }
   */

  @Override
  public Token next(Token token) throws IOException {
    Token result = input.next(token);
    if (result != null) {
      char[] termBuffer = result.termBuffer();
      int len = result.termLength();
      // if protected, don't stem.  use this to avoid stemming collisions.
      if (protWords != null && protWords.contains(termBuffer, 0, len)) {
        return result;
      }
      stemmer.setCurrent(new String(termBuffer, 0, len));//ugh, wish the Stemmer took a char array
      stemmer.stem();
      String newstr = stemmer.getCurrent();
      result.setTermBuffer(newstr.toCharArray(), 0, newstr.length());
    }
    return result;
  }
}

