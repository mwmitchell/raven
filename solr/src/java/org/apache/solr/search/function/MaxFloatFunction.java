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

package org.apache.solr.search.function;

import org.apache.lucene.index.IndexReader;

import java.io.IOException;

/**
 * Returns the max of a ValueSource and a float
 * (which is useful for "bottoming out" another function at 0.0,
 * or some positive number).
 * <br>
 * Normally Used as an argument to a {@link FunctionQuery}
 *
 * @version $Id: MaxFloatFunction.java 555343 2007-07-11 17:46:25Z hossman $
 */
public class MaxFloatFunction extends ValueSource {
  protected final ValueSource source;
  protected final float fval;

  public MaxFloatFunction(ValueSource source, float fval) {
    this.source = source;
    this.fval = fval;
  }
  
  public String description() {
    return "max(" + source.description() + "," + fval + ")";
  }

  public DocValues getValues(IndexReader reader) throws IOException {
    final DocValues vals =  source.getValues(reader);
    return new DocValues() {
      public float floatVal(int doc) {
	float v = vals.floatVal(doc);
        return v < fval ? fval : v;
      }
      public int intVal(int doc) {
        return (int)floatVal(doc);
      }
      public long longVal(int doc) {
        return (long)floatVal(doc);
      }
      public double doubleVal(int doc) {
        return (double)floatVal(doc);
      }
      public String strVal(int doc) {
        return Float.toString(floatVal(doc));
      }
      public String toString(int doc) {
	return "max(" + vals.toString(doc) + "," + fval + ")";
      }
    };
  }

  public int hashCode() {
    int h = Float.floatToIntBits(fval);
    h = (h >>> 2) | (h << 30);
    return h + source.hashCode();
  }

  public boolean equals(Object o) {
    if (MaxFloatFunction.class != o.getClass()) return false;
    MaxFloatFunction other = (MaxFloatFunction)o;
    return  this.fval == other.fval
         && this.source.equals(other.source);
  }
}
