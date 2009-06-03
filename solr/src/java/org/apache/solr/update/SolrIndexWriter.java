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

package org.apache.solr.update;

import org.apache.lucene.index.*;
import org.apache.lucene.store.*;
import org.apache.solr.common.SolrException;
import org.apache.solr.common.util.NamedList;
import org.apache.solr.core.DirectoryFactory;
import org.apache.solr.core.StandardDirectoryFactory;
import org.apache.solr.schema.IndexSchema;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.io.IOException;

/**
 * An IndexWriter that is configured via Solr config mechanisms.
 *
* @version $Id: SolrIndexWriter.java 769506 2009-04-28 19:15:22Z yonik $
* @since solr 0.9
*/


public class SolrIndexWriter extends IndexWriter {
  private static Logger log = LoggerFactory.getLogger(SolrIndexWriter.class);

  String name;
  IndexSchema schema;

  private void init(String name, IndexSchema schema, SolrIndexConfig config) throws IOException {
    log.debug("Opened Writer " + name);
    this.name = name;
    this.schema = schema;
    setSimilarity(schema.getSimilarity());
    // setUseCompoundFile(false);

    if (config != null) {
      setUseCompoundFile(config.useCompoundFile);
      //only set maxBufferedDocs
      if (config.maxBufferedDocs != -1) {
        setMaxBufferedDocs(config.maxBufferedDocs);
      }
      if (config.ramBufferSizeMB != -1) {
        setRAMBufferSizeMB(config.ramBufferSizeMB);
      }
      if (config.maxMergeDocs != -1) setMaxMergeDocs(config.maxMergeDocs);
      if (config.maxFieldLength != -1) setMaxFieldLength(config.maxFieldLength);
      if (config.mergePolicyClassName != null && SolrIndexConfig.DEFAULT_MERGE_POLICY_CLASSNAME.equals(config.mergePolicyClassName) == false) {
        MergePolicy policy = (MergePolicy) schema.getResourceLoader().newInstance(config.mergePolicyClassName);
        setMergePolicy(policy);///hmm, is this really the best way to get a newInstance?
      }
      if (config.mergeFactor != -1 && getMergePolicy() instanceof LogMergePolicy) {
        setMergeFactor(config.mergeFactor);
      }
      if (config.mergeSchedulerClassname != null && SolrIndexConfig.DEFAULT_MERGE_SCHEDULER_CLASSNAME.equals(config.mergeSchedulerClassname) == false) {
        MergeScheduler scheduler = (MergeScheduler) schema.getResourceLoader().newInstance(config.mergeSchedulerClassname);
        setMergeScheduler(scheduler);
      }

      //if (config.commitLockTimeout != -1) setWriteLockTimeout(config.commitLockTimeout);
    }

  }

  public static Directory getDirectory(String path, DirectoryFactory directoryFactory, SolrIndexConfig config) throws IOException {
    
    Directory d = directoryFactory.open(path);

    String rawLockType = (null == config) ? null : config.lockType;
    if (null == rawLockType) {
      // we default to "simple" for backwards compatibility
      log.warn("No lockType configured for " + path + " assuming 'simple'");
      rawLockType = "simple";
    }
    final String lockType = rawLockType.toLowerCase().trim();

    if ("simple".equals(lockType)) {
      // multiple SimpleFSLockFactory instances should be OK
      d.setLockFactory(new SimpleFSLockFactory(path));
    } else if ("native".equals(lockType)) {
      d.setLockFactory(new NativeFSLockFactory(path));
    } else if ("single".equals(lockType)) {
      if (!(d.getLockFactory() instanceof SingleInstanceLockFactory))
        d.setLockFactory(new SingleInstanceLockFactory());
    } else if ("none".equals(lockType)) {
      // Recipe for disaster
      log.error("CONFIGURATION WARNING: locks are disabled on " + path);      
      d.setLockFactory(new NoLockFactory());
    } else {
      throw new SolrException(SolrException.ErrorCode.SERVER_ERROR,
              "Unrecognized lockType: " + rawLockType);
    }
    return d;
  }
  
  /** @deprecated remove when getDirectory(String,SolrIndexConfig) is gone */
  private static DirectoryFactory LEGACY_DIR_FACTORY 
    = new StandardDirectoryFactory();
  static {
    LEGACY_DIR_FACTORY.init(new NamedList());
  }

  /**
   * @deprecated use getDirectory(String path, DirectoryFactory directoryFactory, SolrIndexConfig config)
   */
  public static Directory getDirectory(String path, SolrIndexConfig config) throws IOException {
    log.warn("SolrIndexWriter is using LEGACY_DIR_FACTORY which means deprecated code is likely in use and SolrIndexWriter is ignoring any custom DirectoryFactory.");
    return getDirectory(path, LEGACY_DIR_FACTORY, config);
  }
  
  /**
   *
   */
  public SolrIndexWriter(String name, String path, DirectoryFactory dirFactory, boolean create, IndexSchema schema) throws IOException {
    super(getDirectory(path, dirFactory, null), false, schema.getAnalyzer(), create);
    init(name, schema, null);
  }

  /**
   *
   */
  public SolrIndexWriter(String name, String path, DirectoryFactory dirFactory, boolean create, IndexSchema schema, SolrIndexConfig config) throws IOException {
    super(getDirectory(path, dirFactory, null), config.luceneAutoCommit, schema.getAnalyzer(), create);
    init(name, schema, config);
  }
  
  /**
   * @deprecated
   */
  public SolrIndexWriter(String name, String path, boolean create, IndexSchema schema) throws IOException {
    super(getDirectory(path, null), false, schema.getAnalyzer(), create);
    init(name, schema, null);
  }

  /**
   * @deprecated
   */
  public SolrIndexWriter(String name, String path, boolean create, IndexSchema schema, SolrIndexConfig config) throws IOException {
    super(getDirectory(path, config), config.luceneAutoCommit, schema.getAnalyzer(), create);
    init(name, schema, config);
  }

  public SolrIndexWriter(String name, String path, DirectoryFactory dirFactory, boolean create, IndexSchema schema, SolrIndexConfig config, IndexDeletionPolicy delPolicy) throws IOException {
    super(getDirectory(path, dirFactory, config), schema.getAnalyzer(), create, delPolicy, new MaxFieldLength(IndexWriter.DEFAULT_MAX_FIELD_LENGTH));
    init(name, schema, config);
  }


  /**
   * use DocumentBuilder now...
   * private final void addField(Document doc, String name, String val) {
   * SchemaField ftype = schema.getField(name);
   * <p/>
   * // we don't check for a null val ourselves because a solr.FieldType
   * // might actually want to map it to something.  If createField()
   * // returns null, then we don't store the field.
   * <p/>
   * Field field = ftype.createField(val, boost);
   * if (field != null) doc.add(field);
   * }
   * <p/>
   * <p/>
   * public void addRecord(String[] fieldNames, String[] fieldValues) throws IOException {
   * Document doc = new Document();
   * for (int i=0; i<fieldNames.length; i++) {
   * String name = fieldNames[i];
   * String val = fieldNames[i];
   * <p/>
   * // first null is end of list.  client can reuse arrays if they want
   * // and just write a single null if there is unused space.
   * if (name==null) break;
   * <p/>
   * addField(doc,name,val);
   * }
   * addDocument(doc);
   * }
   * ****
   */

  public void close() throws IOException {
    log.debug("Closing Writer " + name);
    super.close();
  }

  @Override
  protected void finalize() throws Throwable {
    try {
      super.close();
    } finally { 
      super.finalize();
    }
    
  }

}
