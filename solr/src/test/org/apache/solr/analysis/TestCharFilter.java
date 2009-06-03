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

import java.io.StringReader;

import junit.framework.TestCase;

public class TestCharFilter extends TestCase {

  public void testCharFilter1() throws Exception {
    CharStream cs = new CharFilter1( CharReader.get( new StringReader("") ) );
    assertEquals( "corrected offset is invalid", 1, cs.correctOffset( 0 ) );
  }

  public void testCharFilter2() throws Exception {
    CharStream cs = new CharFilter2( CharReader.get( new StringReader("") ) );
    assertEquals( "corrected offset is invalid", 2, cs.correctOffset( 0 ) );
  }

  public void testCharFilter12() throws Exception {
    CharStream cs = new CharFilter2( new CharFilter1( CharReader.get( new StringReader("") ) ) );
    assertEquals( "corrected offset is invalid", 3, cs.correctOffset( 0 ) );
  }

  public void testCharFilter11() throws Exception {
    CharStream cs = new CharFilter1( new CharFilter1( CharReader.get( new StringReader("") ) ) );
    assertEquals( "corrected offset is invalid", 2, cs.correctOffset( 0 ) );
  }

  static class CharFilter1 extends CharFilter {

    protected CharFilter1(CharStream in) {
      super(in);
    }

    @Override
    protected int correct(int currentOff) {
      return currentOff + 1;
    }
  }

  static class CharFilter2 extends CharFilter {

    protected CharFilter2(CharStream in) {
      super(in);
    }

    @Override
    protected int correct(int currentOff) {
      return currentOff + 2;
    }
  }
}
