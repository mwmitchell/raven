package org.apache.solr.analysis;

import org.apache.lucene.analysis.Tokenizer;

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

import org.apache.lucene.analysis.Token;
import org.apache.lucene.analysis.Tokenizer;

import java.io.Reader;


/**
 * CJKTokenizer was modified from StopTokenizer which does a decent job for
 * most European languages. It performs other token methods for double-byte
 * Characters: the token will return at each two characters with overlap match.<br>
 * Example: "java C1C2C3C4" will be segment to: "java" "C1C2" "C2C3" "C3C4" it
 * also need filter filter zero length token ""<br>
 * for Digit: digit, '+', '#' will token as letter<br>
 * for more info on Asia language(Chinese Japanese Korean) text segmentation:
 * please search  <a
 * href="http://www.google.com/search?q=word+chinese+segment">google</a>
 *
 */

/*
 * LUCENE-973 is applied
 */
/**
 *
 * @version $Id: CharStreamAwareCJKTokenizer.java 713902 2008-11-14 01:56:21Z koji $
 * @since Solr 1.4
 *
 */
public final class CharStreamAwareCJKTokenizer extends Tokenizer {
    //~ Static fields/initializers ---------------------------------------------
    /** Word token type */
    static final int WORD_TYPE = 0;

    /** Single byte token type */
    static final int SINGLE_TOKEN_TYPE = 1;

    /** Double byte token type */
    static final int DOUBLE_TOKEN_TYPE = 2;

    /** Names for token types */
    static final String[] TOKEN_TYPE_NAMES = { "word", "single", "double" };

    /** Max word length */
    private static final int MAX_WORD_LEN = 255;

    /** buffer size: */
    private static final int IO_BUFFER_SIZE = 256;

    //~ Instance fields --------------------------------------------------------

    /** word offset, used to imply which character(in ) is parsed */
    private int offset = 0;

    /** the index used only for ioBuffer */
    private int bufferIndex = 0;

    /** data length */
    private int dataLen = 0;

    /**
     * character buffer, store the characters which are used to compose <br>
     * the returned Token
     */
    private final char[] buffer = new char[MAX_WORD_LEN];

    /**
     * I/O buffer, used to store the content of the input(one of the <br>
     * members of Tokenizer)
     */
    private final char[] ioBuffer = new char[IO_BUFFER_SIZE];

    /** word type: single=>ASCII  double=>non-ASCII word=>default */
    private int tokenType = WORD_TYPE;

    /**
     * tag: previous character is a cached double-byte character  "C1C2C3C4"
     * ----(set the C1 isTokened) C1C2 "C2C3C4" ----(set the C2 isTokened)
     * C1C2 C2C3 "C3C4" ----(set the C3 isTokened) "C1C2 C2C3 C3C4"
     */
    private boolean preIsTokened = false;

    //~ Constructors -----------------------------------------------------------

    /**
     * Construct a token stream processing the given input.
     *
     * @param in I/O reader
     */
    public CharStreamAwareCJKTokenizer(CharStream in) {
        input = in;
    }

    //~ Methods ----------------------------------------------------------------

    /**
     * Returns the next token in the stream, or null at EOS.
     * See http://java.sun.com/j2se/1.3/docs/api/java/lang/Character.UnicodeBlock.html
     * for detail.
     *
     * @param reusableToken a reusable token
     * @return Token
     *
     * @throws java.io.IOException - throw IOException when read error <br>
     *         happened in the InputStream
     *
     */
    public final Token next(final Token reusableToken) throws java.io.IOException {
        /** how many character(s) has been stored in buffer */
        assert reusableToken != null;
        int length = 0;

        /** the position used to create Token */
        int start = offset;

        while (true) {
            /** current character */
            char c;

            /** unicode block of current character for detail */
            Character.UnicodeBlock ub;

            offset++;

            if (bufferIndex >= dataLen) {
                dataLen = input.read(ioBuffer);
                bufferIndex = 0;
            }

            if (dataLen == -1) {
                if (length > 0) {
                    if (preIsTokened == true) {
                        length = 0;
                        preIsTokened = false;
                    }

                    break;
                } else {
                    return null;
                }
            } else {
                //get current character
                c = ioBuffer[bufferIndex++];

                //get the UnicodeBlock of the current character
                ub = Character.UnicodeBlock.of(c);
            }

            //if the current character is ASCII or Extend ASCII
            if ((ub == Character.UnicodeBlock.BASIC_LATIN)
                    || (ub == Character.UnicodeBlock.HALFWIDTH_AND_FULLWIDTH_FORMS)
               ) {
                if (ub == Character.UnicodeBlock.HALFWIDTH_AND_FULLWIDTH_FORMS) {
                    // convert  HALFWIDTH_AND_FULLWIDTH_FORMS to BASIC_LATIN
                    int i = (int) c;
                    i = i - 65248;
                    c = (char) i;
                }

                // if the current character is a letter or "_" "+" "#"
                if (Character.isLetterOrDigit(c)
                        || ((c == '_') || (c == '+') || (c == '#'))
                   ) {
                    if (length == 0) {
                        // "javaC1C2C3C4linux" <br>
                        //      ^--: the current character begin to token the ASCII
                        // letter
                        start = offset - 1;
                    } else if (tokenType == DOUBLE_TOKEN_TYPE) {
                        // "javaC1C2C3C4linux" <br>
                        //              ^--: the previous non-ASCII
                        // : the current character
                        offset--;
                        bufferIndex--;

                        if (preIsTokened == true) {
                            // there is only one non-ASCII has been stored
                            length = 0;
                            preIsTokened = false;
                            break;
                        } else {
                            break;
                        }
                    }

                    // store the LowerCase(c) in the buffer
                    buffer[length++] = Character.toLowerCase(c);
                    tokenType = SINGLE_TOKEN_TYPE;

                    // break the procedure if buffer overflowed!
                    if (length == MAX_WORD_LEN) {
                        break;
                    }
                } else if (length > 0) {
                    if (preIsTokened == true) {
                        length = 0;
                        preIsTokened = false;
                    } else {
                        break;
                    }
                }
            } else {
                // non-ASCII letter, e.g."C1C2C3C4"
                if (Character.isLetter(c)) {
                    if (length == 0) {
                        start = offset - 1;
                        buffer[length++] = c;
                        tokenType = DOUBLE_TOKEN_TYPE;
                    } else {
                      if (tokenType == SINGLE_TOKEN_TYPE) {
                            offset--;
                            bufferIndex--;

                            //return the previous ASCII characters
                            break;
                        } else {
                            buffer[length++] = c;
                            tokenType = DOUBLE_TOKEN_TYPE;

                            if (length == 2) {
                                offset--;
                                bufferIndex--;
                                preIsTokened = true;

                                break;
                            }
                        }
                    }
                } else if (length > 0) {
                    if (preIsTokened == true) {
                        // empty the buffer
                        length = 0;
                        preIsTokened = false;
                    } else {
                        break;
                    }
                }
            }
        }

        if (length > 0) {
            // Because of "CharStream aware" tokenizer, using correctOffset() to
            // correct start/end offsets
            return reusableToken.reinit
                (buffer, 0, length,
                	((CharStream)input).correctOffset( start ),
                	((CharStream)input).correctOffset( start+length ),
                	TOKEN_TYPE_NAMES[tokenType]);
        } else if (dataLen != -1) {
            // Don't return an empty string - recurse to get the next token
            return next(reusableToken);
        } else {
          return null;
        }
    }
}
