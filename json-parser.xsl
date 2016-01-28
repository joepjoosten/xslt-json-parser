<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:j="urn:xslt-json-parser:json-parser"
    xmlns:t="urn:xslt-json-parser:token"
    xmlns:p="urn:xslt-json-parser:parser"
    xmlns:f="urn:xslt-json-parser:functions"
    exclude-result-prefixes="f j p t xs">

    <!--
    Parse a JSON string (JSON.org dialect) to a XML tree
      $unparsed-json the unparsed JSON string
      Returns a XML tree representation of the JSON string:

      E.g. the following JSON string converts to

      {"myArray": [null, true, false, "A String", 1234.1234], "Another pair": true}

      Converts to:

      <object>
        <pair name="myArray">
            <array>
                <null/>
                <boolean>true</boolean>
                <boolean>false</boolean>
                <string>A String</string>
                <number>1234.1234</number>
            </array>
        </pair>
        <pair name="Another pair">
            <boolean>true</boolean>
        </pair>
      </object>

    -->
    <xsl:function name="j:parse-json">
        <xsl:param name="unparsed-json" as="xs:string"/>

        <xsl:variable name="tokens" as="item()+" select="p:tokenize-json($unparsed-json)"/>
        <xsl:variable name="closure" as="item()+">
            <xsl:call-template name="p:parse-json">
                <xsl:with-param name="tokens" tunnel="yes" select="$tokens"/>
                <xsl:with-param name="index" tunnel="yes" select="1"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="next" as="xs:integer" select="$closure[1]"/>
        <xsl:variable name="expression" as="element()" select="$closure[2]"/>
        
        <xsl:if test="exists($tokens[$next])">
            <xsl:sequence select="error(xs:QName('error'), concat('Invalid token: ', $tokens[$next], ' ''', $tokens[$next + 1], ''''))"/>
        </xsl:if>
        
        <xsl:sequence select="$expression"/>
    </xsl:function>

    <!-- Tokens. -->

    <!-- Token defining left object. -->
    <xsl:variable name="t:left-object" as="xs:QName" select="xs:QName('t:left-object')"/>

    <!-- Token defining right object. -->
    <xsl:variable name="t:right-object" as="xs:QName" select="xs:QName('t:right-object')"/>

    <!-- Token defining left array. -->
    <xsl:variable name="t:left-array" as="xs:QName" select="xs:QName('t:left-array')"/>
    
    <!-- Token defining right array. -->
    <xsl:variable name="t:right-array" as="xs:QName" select="xs:QName('t:right-array')"/>

    <!-- Token defining pair seperator. -->
    <xsl:variable name="t:pair-seperator" as="xs:QName" select="xs:QName('t:pair-seperator')"/>
    
    <!-- Token defining element seperator. -->
    <xsl:variable name="t:element-seperator" as="xs:QName" select="xs:QName('t:element-seperator')"/>
    
    <!-- Token defining boolean literal. -->
    <xsl:variable name="t:boolean" as="xs:QName" select="xs:QName('t:boolean')"/>
    
    <!-- Token defining number literal. -->
    <xsl:variable name="t:number" as="xs:QName" select="xs:QName('t:number')"/>
    
    <!-- Token defining null literal. -->
    <xsl:variable name="t:null" as="xs:QName" select="xs:QName('t:null')"/>
    
    <!-- Token defining number literal. -->
    <xsl:variable name="t:string" as="xs:QName" select="xs:QName('t:string')"/>

    <!--
      Tokenizes an JSON string and returns as sequence of tokens.
      Each token is a pair (token-qname, token-string-value).
      $json-string - an JSON string to tokenize.
      Returns as sequence of tokens.
    -->
    <xsl:function name="p:tokenize-json" as="item()*">
        <xsl:param name="json-string" as="xs:string"/>

        <xsl:analyze-string
            regex="
      (\s+) |
      (\{{) |
      (\}}) |
      (\[) |
      (\]) |
      (,) |
      (:) |
      (null) |
      (true) |
      (false) |
      (&quot;[^&quot;\\]*( ( ((\\[\\/bfnrt&quot;]) | (\\u([0-9A-Fa-f]{{4}})) )[^&quot;\\]*)*&quot;)) | 
      ((([-]?[0-9]+)?\.)?[-]?[0-9]+([eE][-+]?[0-9]+)? )"
            flags="imx" select="$json-string">
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="regex-group(1)">
                        <!-- Skip space. -->
                    </xsl:when>
                    <xsl:when test="regex-group(2)">
                        <xsl:sequence select="$t:left-object, regex-group(2)"/>
                    </xsl:when>
                    <xsl:when test="regex-group(3)">
                        <xsl:sequence select="$t:right-object, regex-group(3)"/>
                    </xsl:when>
                    <xsl:when test="regex-group(4)">
                        <xsl:sequence select="$t:left-array, regex-group(4)"/>
                    </xsl:when>
                    <xsl:when test="regex-group(5)">
                        <xsl:sequence select="$t:right-array, regex-group(5)"/>
                    </xsl:when>
                    <xsl:when test="regex-group(6)">
                        <xsl:sequence select="$t:element-seperator, regex-group(6)"/>
                    </xsl:when>
                    <xsl:when test="regex-group(7)">
                        <xsl:sequence select="$t:pair-seperator, regex-group(7)"/>
                    </xsl:when>
                    <xsl:when test="regex-group(8)">
                        <xsl:sequence select="$t:null, regex-group(8)"/>
                    </xsl:when>
                    <xsl:when test="regex-group(9)">
                        <xsl:sequence select="$t:boolean, regex-group(9)"/>
                    </xsl:when>
                    <xsl:when test="regex-group(10)">
                        <xsl:sequence select="$t:boolean, regex-group(10)"/>
                    </xsl:when>
                    <xsl:when test="regex-group(11)">
                        <xsl:variable name="parsed-string">
                            <xsl:analyze-string regex="\\u([0-9a-fA-F]{{4}})" select="regex-group(11)">
                                <xsl:matching-substring>
                                    <xsl:value-of select="codepoints-to-string(f:hex-to-int(regex-group(1)))"/>
                                </xsl:matching-substring>
                                <xsl:non-matching-substring>
                                    <xsl:value-of select="."/>
                                </xsl:non-matching-substring>
                            </xsl:analyze-string>
                        </xsl:variable>
                        <xsl:sequence select="$t:string, 
                            replace(
                                replace(
                                    replace(
                                        replace(
                                        replace($parsed-string, '&quot;(.*)&quot;', '$1'),
                                            '\\&quot;', '&quot;'
                                            ),
                                        '\\r','&#13;'
                                        ),
                                    '\\n', '&#10;'
                                    ),
                                '\\t', '&#9;'
                            )"/>
                    </xsl:when>
                    <xsl:when test="regex-group(18)">
                        <xsl:sequence select="$t:number, regex-group(18)"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="error(xs:QName('error'), concat('Invalid token: ''', ., ''''))"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <!--
    Parses an tokenized JSON string.
      $tokens - a sequence of tokens to parse.
      $intex - a token index.
      Returns a closure of next token index and parsed JSON string.
    -->
    <xsl:template name="p:parse-json" as="item()+">
        <xsl:param name="tokens" tunnel="yes" as="item()+"/>
        <xsl:param name="index" tunnel="yes" as="xs:integer"/>

        <xsl:call-template name="p:parse-parenthesis-expression"/>
    </xsl:template>

    <!--
    Parses a parenthesis group (array or object).
      $tokens - expression tokens.
      $index - token index.
      Returns a closure of next token index and parsed parenthesis group.
    -->
    <xsl:template name="p:parse-parenthesis-expression" as="item()+">
        <xsl:param name="tokens" tunnel="yes" as="item()+"/>
        <xsl:param name="index" tunnel="yes" as="xs:integer"/>

        <xsl:choose>
            <xsl:when test="$tokens[$index] eq $t:left-object">
                <xsl:variable name="closure" as="item()+">
                    <xsl:call-template name="p:parse-object">
                        <xsl:with-param name="index" tunnel="yes" select="$index + 2"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="next" as="xs:integer" select="$closure[1]"/>
                <xsl:variable name="param" as="element()" select="$closure[2]"/>

                <xsl:if test="not($tokens[$next] eq $t:right-object)">
                    <xsl:sequence select="error(xs:QName('error'), 'A object close parenthesis is expected.')"/>
                </xsl:if>

               <xsl:sequence select="$next + 2"/>
               <xsl:sequence select="$param"/>
            </xsl:when>
            <xsl:when test="$tokens[$index] eq $t:left-array">
                <xsl:variable name="closure" as="item()+">
                    <xsl:call-template name="p:parse-array">
                        <xsl:with-param name="index" tunnel="yes" select="$index + 2"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:variable name="next" as="xs:integer" select="$closure[1]"/>
                <xsl:variable name="param" as="element()" select="$closure[2]"/>
                
                <xsl:if test="not($tokens[$next] eq $t:right-array)">
                    <xsl:sequence select="error(xs:QName('error'), 'A array close parenthesis is expected.')"/>
                </xsl:if>
                
                <xsl:sequence select="$next + 2"/>
                <xsl:sequence select="$param"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="p:parse-value"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
    Parses a json object.
      $tokens - json tokens.
      $index - token index.
      Returns a closure of next token index and parsed object.
    -->
    <xsl:template name="p:parse-object">
        <xsl:param name="tokens" tunnel="yes" as="item()+"/>
        <xsl:param name="index" tunnel="yes" as="xs:integer"/>
        <xsl:param name="collected" as="element()*"/>
        
        <xsl:choose>
            <xsl:when test="not($tokens[$index] eq $t:right-object)">
                
                <xsl:variable name="closure" as="item()+">
                    <xsl:call-template name="p:parse-pair"/>
                </xsl:variable>
                
                <xsl:variable name="next" as="xs:integer" select="$closure[1]"/>
                <xsl:variable name="param" as="element()" select="$closure[2]"/>
                
                <xsl:variable name="result" as="element()+">
                    <xsl:choose>
                        <xsl:when test="$collected">
                            <xsl:sequence select="$collected, $param"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="$param"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:choose>
                    <xsl:when test="$tokens[$next] eq $t:element-seperator">
                        <xsl:call-template name="p:parse-object">
                            <xsl:with-param name="index" tunnel="yes" select="$next + 2"/>
                            <xsl:with-param name="collected" select="$result"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$next"/>
                        <object>
                            <xsl:sequence select="$result"/>
                        </object>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$index"/>
                <object/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
    Parses a json array.
      $tokens - json tokens.
      $index - token index.
      Returns a closure of next token index and parsed array.
    -->
    <xsl:template name="p:parse-array">
        <xsl:param name="tokens" tunnel="yes" as="item()+"/>
        <xsl:param name="index" tunnel="yes" as="xs:integer"/>
        <xsl:param name="collected" as="element()*"/>
        
        <xsl:choose>
            <xsl:when test="not($tokens[$index] eq $t:right-array)">
                
                <xsl:variable name="closure" as="item()+">
                    <xsl:call-template name="p:parse-value"/>
                </xsl:variable>
                
                <xsl:variable name="next" as="xs:integer" select="$closure[1]"/>
                <xsl:variable name="param" as="element()" select="$closure[2]"/>
                
                <xsl:variable name="result" as="element()+">
                    <xsl:choose>
                        <xsl:when test="$collected">
                            <xsl:sequence select="$collected, $param"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="$param"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:choose>
                    <xsl:when test="$tokens[$next] eq $t:element-seperator">
                        <xsl:call-template name="p:parse-array">
                            <xsl:with-param name="index" tunnel="yes" select="$next + 2"/>
                            <xsl:with-param name="collected" select="$result"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$next"/>
                        <array>
                            <xsl:sequence select="$result"/>
                        </array>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$index"/>
                <array/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
    Parses a value.
      $tokens - json tokens.
      $index - token index.
      Returns a closure of next token index and parsed value.
    -->
    <xsl:template name="p:parse-value" as="item()+">
        <xsl:param name="tokens" tunnel="yes" as="item()+"/>
        <xsl:param name="index" tunnel="yes" as="xs:integer"/>

        <xsl:variable name="token" as="xs:QName?" select="$tokens[$index]"/>

        <xsl:choose>
            <xsl:when test="$token eq $t:boolean">
                <xsl:sequence select="$index + 2"/>
                <boolean>
                    <xsl:sequence select="$tokens[$index + 1]"/>
                </boolean>
            </xsl:when>
            <xsl:when test="$token eq $t:number">
                <xsl:sequence select="$index + 2"/>
                <number>
                    <xsl:sequence select="$tokens[$index + 1]"/>
                </number>
            </xsl:when>
            <xsl:when test="$token eq $t:null">
                <xsl:sequence select="$index + 2"/>
                <null/>
            </xsl:when>
            <xsl:when test="$token eq $t:string">
                <xsl:sequence select="$index + 2"/>
                <string>
                    <xsl:sequence select="$tokens[$index + 1]"/>
                </string>
            </xsl:when>
            <xsl:when test="$token eq $t:left-array or $token eq $t:left-object">
                <xsl:variable name="closure" as="item()+">
                    <xsl:call-template name="p:parse-parenthesis-expression"/>
                </xsl:variable>
                
                <xsl:sequence select="$closure[1]"/>
                <xsl:sequence select="$closure[2]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="error(xs:QName('error'), concat('Invalid token: ', $token, ' ''', $tokens[$index + 1], ''''))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!--
    Parses a json pair.
      $tokens - json tokens.
      $index - token index.
      Returns a closure of next token index and parsed json pair.
    -->
    <xsl:template name="p:parse-pair" as="item()+">
        <xsl:param name="tokens" tunnel="yes" as="item()+"/>
        <xsl:param name="index" tunnel="yes" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$tokens[$index] eq $t:string and $tokens[$index+2] eq $t:pair-seperator">
                <xsl:variable name="closure" as="item()+">
                    <xsl:call-template name="p:parse-json">
                        <xsl:with-param name="index" tunnel="yes" select="$index + 4"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:sequence select="$closure[1]"/>
                <pair name="{$tokens[$index+1]}">
                    <xsl:sequence select="$closure[2]"/>
                </pair>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="error(xs:QName('error'), concat('A object pair expected, but got invalid token: ', $tokens[$index+2], ' ''', $tokens[$index + 3], ''''))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
        Convert a hexadecimal string into a integer
    -->
    <xsl:function name="f:hex-to-int" as="xs:integer">
        <xsl:param name="in"/> <!-- e.g. 030C -->
        <xsl:sequence select="
            if (string-length($in) eq 1) then 
                f:hex-digit-to-integer($in)
            else 
                16*f:hex-to-int(substring($in, 1, string-length($in)-1)) +
                f:hex-digit-to-integer(substring($in, string-length($in)))"/>
    </xsl:function>

    <!--
        Convert a hexadecimal character into a integer
    -->
    <xsl:function name="f:hex-digit-to-integer" as="xs:integer">
        <xsl:param name="char"/>
        <xsl:sequence select="string-length(substring-before('0123456789ABCDEF', upper-case($char)))"/>
    </xsl:function>

</xsl:stylesheet>
