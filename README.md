xslt-json-parser
================

XSLT 2.0 JSON parser for the json.org dialect.

Example usage:
===============

The XML file

```XML
<?xml version="1.0" encoding="utf-8"?>
<data>{"myArray": [null, true, false, "A String", 1234.1234], "Another pair": true}</data>
```

The XSL file

```XSLT
<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:j="urn:xslt-json-parser:json-parser">
    
    <xsl:output indent="yes"/>
    
    <xsl:import href="json-parser.xsl"/>
    
    <xsl:template match="/">
        <xsl:copy-of select="j:parse-json(data)"/>
    </xsl:template>
</xsl:stylesheet>
```
