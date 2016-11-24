<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	xmlns:vm="http://www.ivoa.net/xml/VOMetadata/v0.1" 
	version="1.0">
<!-- This stylesheet produces LaTeX source for one (simple or complex) 
type taken from an XML schema file.  The name of the type is taken from
the destType schema parameter.

This file is part of the IVOATeX document production system.  It was derived
from Ray Plante's XSLT files for producing HTML documentation from schema
files.

This file can be distributed under the GNU GPL.  See COPYING for details.

Copyright 2015, The GAVO project
-->

  <xsl:output method="text"/>

  <xsl:param name="indentstep" select="'  '"/>
  <xsl:param name="maxcodelen" select="72"/>
  <xsl:param name="showDefaults" select="true()"/>
  <xsl:param name="xsdprefix">xs</xsl:param>

  <xsl:template match="text()"/>

  <xsl:template name="escape-for-TeX">
  	<xsl:param name="tx"/>
  	<xsl:text>escape-for-TeX{{{</xsl:text>
 			<xsl:value-of select="$tx"/>
  	<xsl:text>}}}</xsl:text>
  </xsl:template>

	<xsl:template match="vm:dcterm"/> <!-- we don't have a good place for these
		yet -->
	
  <xsl:template match="xs:complexType[xs:simpleContent]" mode="content"/>

  <xsl:template match="xs:complexType" mode="content">
    <xsl:if test=".//xs:element">
      <xsl:apply-templates select=".//xs:element" mode="content"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xs:simpleType" mode="content"/>

  <xsl:template match="xs:complexType|xs:simpleType" mode="attributes">
    <xsl:if test=".//xs:attribute">
      <xsl:attribute namespace="" name="title">
        <xsl:value-of select="concat(/xs:schema/xs:annotation/xs:appinfo/vm:targetPrefix,':',@name)"/>
        <xsl:text> Attributes</xsl:text>
      </xsl:attribute>
      <xsl:text>&#10;</xsl:text>
      <xsl:apply-templates select=".//xs:attribute" mode="attributes"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>
  <xsl:template match="xs:element" mode="content">
    <xsl:text>\item[Element \xmlel{</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>}]&#10;\begin{description}&#10;</xsl:text>
    <xsl:apply-templates select="." mode="nextContentItem"/>
    <xsl:text>&#10;\end{description}&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xs:element" mode="nextContentItem">
    <xsl:param name="row" select="1"/>
    <xsl:param name="item" select="1"/>
    <xsl:variable name="type" select="@type"/>
    <xsl:choose>
      <xsl:when test="$item &lt; 3">
        <xsl:apply-templates select="." mode="content.type">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="nextContentItem">
          <xsl:with-param name="row" select="$row+1"/>
          <xsl:with-param name="item" select="3"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$item &lt; 4">
        <xsl:apply-templates select="." mode="content.meaning">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="nextContentItem">
          <xsl:with-param name="row" select="$row+1"/>
          <xsl:with-param name="item" select="4"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$item &lt; 5">
        <xsl:apply-templates select="." mode="content.occurrences">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="nextContentItem">
          <xsl:with-param name="row" select="$row+1"/>
          <xsl:with-param name="item" select="5"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$item &lt; 6 and
      	(xs:simpleType/xs:restriction or                             
      		(starts-with($type,/xs:schema/xs:annotation/xs:appinfo/vm:targetPrefix)
      		and /xs:schema/xs:simpleType[@name=substring-after($type,':')]/xs:restriction))">
        <xsl:apply-templates select="." mode="content.allowedValues">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="nextContentItem">
          <xsl:with-param name="row" select="$row+1"/>
          <xsl:with-param name="item" select="6"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$item &lt; 7 and count(xs:annotation/xs:documentation) &gt; 1">
        <xsl:apply-templates select="." mode="content.comment">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xs:element|xs:attribute" mode="content.type">
    <xsl:param name="row" select="1"/>
    <xsl:variable name="type">
      <xsl:text>\item[Type] </xsl:text>
      <xsl:choose>
        <xsl:when test="@type">
          <xsl:apply-templates select="@type" mode="type"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="xs:complexType|xs:simpleType" mode="type"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <type row="{$row}">
      <xsl:copy-of select="$type"/>
    </type>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xs:element|xs:attribute" mode="content.meaning">
    <xsl:param name="row" select="1"/>
    <xsl:text>\item[Meaning] </xsl:text>
    <xsl:call-template name="escape-for-TeX">
	    <xsl:with-param name="tx" select="xs:annotation/xs:documentation[1]"/>
	  </xsl:call-template>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xs:attribute" mode="content.default">
    <xsl:param name="row" select="1"/>
    <default row="{$row}">
      <xsl:value-of select="@default"/>
    </default>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xs:element" mode="content.occurrences">
    <xsl:param name="row" select="1"/>
    <xsl:apply-templates select="." mode="occurrences"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xs:element" mode="occurrences">
    <xsl:text>\item[Occurrence] </xsl:text>
    <xsl:choose>
      <xsl:when test="@minOccurs='0'">
        <xsl:text>optional</xsl:text>
        <xsl:choose>
          <xsl:when test="@maxOccurs='unbounded'">
            <xsl:text>; multiple occurrences allowed.</xsl:text>
          </xsl:when>
          <xsl:when test="@maxOccurs and @maxOccurs!='0' and                                  @maxOccurs!='1'">
            <xsl:text>; up to </xsl:text>
            <xsl:value-of select="@maxOccurs"/>
            <xsl:text> occurrences allowed.</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="(not(@minOccurs) or @minOccurs='1')">
        <xsl:text>required</xsl:text>
        <xsl:choose>
          <xsl:when test="@maxOccurs='unbounded'">
            <xsl:text>; multiple occurrences allowed.</xsl:text>
          </xsl:when>
          <xsl:when test="@maxOccurs and @maxOccurs!='0' and                                 @maxOccurs!='1'">
            <xsl:text>; up to </xsl:text>
            <xsl:value-of select="@maxOccurs"/>
            <xsl:text> occurrences allowed.</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="@minOccurs=@maxOccurs">
            <xsl:text>exactly </xsl:text>
            <xsl:value-of select="@minOccurs"/>
            <xsl:text> occurrences required.</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>at least </xsl:text>
            <xsl:value-of select="@minOccurs"/>
            <xsl:text> occurrences required; </xsl:text>
            <xsl:choose>
              <xsl:when test="@maxOccurs='unbounded'">
                <xsl:text>more are allowed</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>no more than </xsl:text>
                <xsl:value-of select="@maxOccurs"/>
                <xsl:text> allowed.</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xs:attribute" mode="content.occurrences">
    <xsl:param name="row" select="1"/>
    <xsl:apply-templates select="." mode="occurrences"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
  <xsl:template match="xs:attribute" mode="occurrences">
    <xsl:text>\item[Occurrence] </xsl:text>
    <xsl:choose>
      <xsl:when test="@use='required'">required</xsl:when>
      <xsl:otherwise>optional</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xs:element|xs:attribute" mode="content.allowedValues">
    <xsl:param name="row" select="1"/>
    <xsl:param name="type" select="@type"/>
   	<xsl:attribute namespace="" name="row">
     	<xsl:value-of select="$row"/>
   	</xsl:attribute>
   	<xsl:text>&#10;</xsl:text>
   	<xsl:choose>
     	<xsl:when test="$type">
     		<xsl:if test="/xs:schema/xs:simpleType[@name=substring-after($type,':')]/xs:restriction/xs:enumeration">
 					<xsl:text>\item[Allowed Values]\hfil&#10;\begin{longtermsdescription}&#10;</xsl:text>
       			<xsl:apply-templates select="/xs:schema/xs:simpleType[@name=substring-after($type,':')]/xs:restriction/xs:enumeration" mode="controlledVocab"/>
   				<xsl:text>\end{longtermsdescription}&#10;</xsl:text>
       	</xsl:if>
     	</xsl:when>
     	<xsl:otherwise>
   			<xsl:if test="descendant::xs:enumeration">
 					<xsl:text>\item[Allowed Values]\hfil&#10;\begin{longtermsdescription}</xsl:text>
       		<xsl:apply-templates 
       			select="descendant::xs:enumeration" 
       			mode="controlledVocab"/>
   				<xsl:text>\end{longtermsdescription}&#10;</xsl:text>
       	</xsl:if>
     	</xsl:otherwise>
   	</xsl:choose>
  </xsl:template>

  <xsl:template match="xs:element|xs:attribute" mode="content.comment">
    <xsl:param name="row" select="1"/>
    <xsl:for-each select="xs:annotation/xs:documentation[position() &gt; 1]">
      <xsl:text>\item[Comment] </xsl:text>
      <xsl:attribute namespace="" name="row">
        <xsl:value-of select="$row"/>
      </xsl:attribute>
      <xsl:call-template name="escape-for-TeX">
	    	<xsl:with-param name="tx" select="."/>
      </xsl:call-template>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="@type[.='xs:boolean']" priority="1" mode="type">
    <xsl:text>boolean (true/false): </xsl:text>
    <code>
      <xsl:value-of select="."/>
    </code>
  </xsl:template>

  <xsl:template match="@type[.='vr:ResourceName']" priority="1" mode="type">
    <xsl:text>string with ID attribute: </xsl:text>
    <code>
      <a href="http://www.ivoa.net/Documents/REC/ReR/VOResource-20080222.html#d:ResourceName">
        <xsl:text>vr:ResourceName</xsl:text>
      </a>
    </code>
  </xsl:template>

  <xsl:template match="@type[.='vr:IdentifierURI']" priority="1" mode="type">
    <xsl:text>an IVOA Identifier URI: </xsl:text>
    <code>
      <a href="http://www.ivoa.net/Documents/REC/ReR/VOResource-20080222.html#d:IdentifierURI">
        <xsl:text>vr:IdentifierURI</xsl:text>
      </a>
    </code>
  </xsl:template>

  <xsl:template match="@type[starts-with(., 'vr:')]" mode="type">
    <xsl:text>composite: \xmlel{</xsl:text>
      <xsl:value-of select="."/>}</xsl:template>

  <xsl:template match="@type[starts-with(., 'xs:')]" mode="type">
    <xsl:choose>
      <xsl:when test=".='xs:token' or .='xs:string'">
        <xsl:text>string: \xmlel{</xsl:text>
          <xsl:value-of select="."/>}</xsl:when>
      <xsl:when test=".='xs:integer'">
        <xsl:text>integer</xsl:text>
      </xsl:when>
      <xsl:when test=".='xs:NCName'">
        <xsl:text>a prefixless XML name</xsl:text>
      </xsl:when>
      <xsl:when test=".='xs:decimal' or .='xs:float' or .='xs:double'">
        <xsl:text>floating-point number: \xmlel{</xsl:text>
          <xsl:value-of select="."/>}</xsl:when>
      <xsl:when test=".='xs:anyURI'">
        <xsl:text>a URI: \xmlel{</xsl:text>
          <xsl:value-of select="."/>}</xsl:when>
      <xsl:otherwise>
      	<xsl:text>\xmlel{</xsl:text>
				<xsl:value-of select="."/>}</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@type[starts-with(., /xs:schema/xs:annotation/xs:appinfo/vm:targetPrefix)]" 
  		mode="type">
    <xsl:variable name="type" select="substring-after(.,':')"/>
    <xsl:choose>
      <xsl:when test="/xs:schema/xs:simpleType[@name=$type]">
        <xsl:apply-templates select="/xs:schema/xs:simpleType[@name=$type]" mode="type"/>
      </xsl:when>
      <xsl:when test="/xs:schema/xs:complexType[@name=$type]/xs:simpleContent/xs:extension">
        <xsl:for-each select="/xs:schema/xs:complexType[@name=$type]/xs:simpleContent/xs:extension">
          <xsl:choose>
            <xsl:when test="@base='xs:string' or @base='xs:token'">
              <xsl:text>a string</xsl:text>
            </xsl:when>
            <xsl:when test="@base='xs:anyURI'">
              <xsl:text>a URI</xsl:text>
            </xsl:when>
            <xsl:when test="@base='xs:NCName'">
              <xsl:text>an XML name without a namespace prefix</xsl:text>
            </xsl:when>
            <xsl:when test="@base='xs:integer'">
              <xsl:text>an integer</xsl:text>
            </xsl:when>
            <xsl:when test="@base='xs:nonNegativeInteger'">
              <xsl:text>a non-negative integer (0, 1, ...)</xsl:text>
            </xsl:when>
            <xsl:when test="@base='xs:decimal' 
            		or @base='xs:float' 
            		or @base='xsdouble'">
              <xsl:text>a floating point number (\xmlel{</xsl:text>
                <xsl:value-of select="@base"/>
              <xsl:text>})</xsl:text>
            </xsl:when>
            <xsl:when test="@base='boolean'">
              <xsl:text>a boolean value (true, false, 0, or 1)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>\xmlel{</xsl:text>
                <xsl:value-of select="@base"/>}</xsl:otherwise>
          </xsl:choose>
          <xsl:text> with optional attributes</xsl:text>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>composite: \xmlel{</xsl:text>
          <xsl:value-of select="."/>}</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xs:simpleType" mode="type">
    <xsl:choose>
      <xsl:when test="xs:restriction[@base='xs:string' 
      		or @base='xs:token']/xs:enumeration">
        <xsl:text>string with controlled vocabulary</xsl:text>
      </xsl:when>
      <xsl:when test="xs:restriction[@base='xs:string' 
      		or @base='xs:token']/xs:pattern">
        <xsl:text>string of the form: \emph{</xsl:text>
          <xsl:value-of select="xs:restriction/xs:pattern/@value"/>
        <xsl:text>}</xsl:text>
      </xsl:when>
      <xsl:otherwise>string</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@type" mode="type">
    <xsl:text>\xmlel{</xsl:text>
      <xsl:value-of select="."/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="xs:enumeration" mode="controlledVocab">
    <xsl:text>\item[</xsl:text>
    <xsl:call-template name="escape-for-TeX">
    	<xsl:with-param name="tx" select="@value"/>
    </xsl:call-template>
    <xsl:text>]</xsl:text>
    <xsl:call-template name="escape-for-TeX">
	     <xsl:with-param name="tx" 
	     	select="xs:annotation/xs:documentation"/>
	   </xsl:call-template>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xs:attribute" mode="attributes">
    <xsl:text>\item[</xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>]&#10;\begin{description}&#10;</xsl:text>
    <xsl:apply-templates select="." mode="nextContentItem"/>
    <xsl:text>\end{description}&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xs:attribute" mode="nextContentItem">
    <xsl:param name="row" select="1"/>
    <xsl:param name="item" select="1"/>
    <xsl:variable name="type" select="@type"/>
    <xsl:choose>
      <xsl:when test="$item &lt; 2">
        <xsl:apply-templates select="." mode="content.type">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="nextContentItem">
          <xsl:with-param name="row" select="$row+1"/>
          <xsl:with-param name="item" select="2"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$item &lt; 3">
        <xsl:apply-templates select="." mode="content.meaning">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="nextContentItem">
          <xsl:with-param name="row" select="$row+1"/>
          <xsl:with-param name="item" select="3"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$item &lt; 4">
        <xsl:apply-templates select="." mode="content.occurrences">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="nextContentItem">
          <xsl:with-param name="row" select="$row+1"/>
          <xsl:with-param name="item" select="4"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$item &lt; 5 and                            
      	(xs:simpleType/xs:restriction or                             
      	(starts-with($type,/xs:schema/xs:annotation/xs:appinfo/vm:targetPrefix) 
      		and /xs:schema/xs:simpleType[@name=substring-after($type,':')]/xs:restriction))">
        <xsl:apply-templates select="." mode="content.allowedValues">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="nextContentItem">
          <xsl:with-param name="row" select="$row+1"/>
          <xsl:with-param name="item" select="5"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$item &lt; 6 and @default and $showDefaults">
        <xsl:apply-templates select="." mode="content.default">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="nextContentItem">
          <xsl:with-param name="row" select="$row+1"/>
          <xsl:with-param name="item" select="6"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$item &lt; 7 and count(xs:annotation/xs:documentation) &gt; 1">
        <xsl:apply-templates select="." mode="content.comment">
          <xsl:with-param name="row" select="$row"/>
        </xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="xsdcode">
    <xsl:param name="indent"/>
    <xsl:param name="step" select="$indentstep"/>
    <xsl:value-of select="$indent"/>
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="concat($xsdprefix, ':', local-name())"/>
    <xsl:apply-templates select="." mode="formatAttrs">
      <xsl:with-param name="elindent" select="$indent"/>
    </xsl:apply-templates>
    <xsl:choose>
      <xsl:when test="*[local-name()!='annotation']">
        <xsl:text>&gt;</xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:apply-templates 
        	select="*[local-name()!='annotation']" mode="xsdcode">
          <xsl:with-param name="indent" select="concat($indent,$step)"/>
        </xsl:apply-templates>
        <xsl:value-of select="$indent"/>
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="concat($xsdprefix, ':', local-name())"/>
        <xsl:text>&gt;</xsl:text>
      </xsl:when>
      <xsl:when test="*">
        <xsl:text>/&gt;</xsl:text>
      </xsl:when>
      <xsl:when test="text()">
        <xsl:text>&gt;</xsl:text>
        <xsl:value-of select="text()"/>
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="concat($xsdprefix, ':', local-name())"/>
        <xsl:text>&gt;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>/&gt;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="*" mode="formatAttrs">
    <xsl:param name="elindent"/>
    <xsl:param name="indent">
      <xsl:value-of select="$elindent"/>
      <xsl:call-template name="indentFor">
        <xsl:with-param name="in" select="concat($xsdprefix,local-name())"/>
      </xsl:call-template>
    </xsl:param>
    <xsl:param name="c" select="count(@*)"/>
    <xsl:param name="to"/>
    <xsl:variable name="i" select="count(@*)-$c+1"/>
    <xsl:variable name="appended">
      <xsl:apply-templates select="@*[$i]" mode="appendAttr">
        <xsl:with-param name="to" select="$to"/>
        <xsl:with-param name="indent" select="$indent"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$c &gt; 1">
        <xsl:apply-templates select="." mode="formatAttrs">
          <xsl:with-param name="to" select="$appended"/>
          <xsl:with-param name="c" select="$c - 1"/>
          <xsl:with-param name="indent" select="$indent"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$appended"/>
        <xsl:if test="$appended">
          <xsl:text> </xsl:text>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@*" mode="appendAttr">
    <xsl:param name="to"/>
    <xsl:param name="indent"/>
    <xsl:param name="maxlen" select="$maxcodelen"/>
    <xsl:variable name="attr">
      <xsl:apply-templates select="." mode="formatAttr"/>
    </xsl:variable>
    <xsl:value-of select="$to"/>
    <xsl:if test="string-length($attr)+string-length($to)+string-length($attr) &gt; $maxcodelen">
      <xsl:text>&#10;</xsl:text>
      <xsl:value-of select="$indent"/>
    </xsl:if>
    <xsl:value-of select="$attr"/>
  </xsl:template>

  <xsl:template match="@*" mode="formatAttr">
    <xsl:text> </xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
  </xsl:template>

  <xsl:template name="indentFor">
    <xsl:param name="in"/>
    <xsl:if test="$in">
      <xsl:text> </xsl:text>
      <xsl:call-template name="indentFor">
        <xsl:with-param name="in" select="substring($in,2)"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xs:complexType|xs:simpleType" mode="attributeTitle">
    <xsl:text>\xmlel{</xsl:text>
    <xsl:value-of select="concat(/xs:schema/xs:annotation/xs:appinfo/vm:targetPrefix,':',@name)"/>
    <xsl:text>}</xsl:text>
    <xsl:text> Attributes</xsl:text>
  </xsl:template>

  <xsl:template match="xs:complexType" mode="MetadataTitle">
    <xsl:text>\xmlel{</xsl:text>
    <xsl:value-of select="concat(/xs:schema/xs:annotation/xs:appinfo/vm:targetPrefix,':',@name)"/>
    <xsl:text>}</xsl:text>
    <xsl:choose>
      <xsl:when test=".//xs:extension">
        <xsl:text> Extension Metadata Elements</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text> Metadata Elements</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xs:complexType|xs:simpleType" mode="xsddef">
    <xsl:text>\begin{lstlisting}[language=XML,basicstyle=\footnotesize]&#10;</xsl:text>
    <xsl:apply-templates select="." mode="xsdcode"/>
    <xsl:text>\end{lstlisting}</xsl:text>
  </xsl:template>

	<xsl:template match="xs:documentation" mode="typedesc">
		<xsl:text>\noindent{\small</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>\par}&#10;&#10;</xsl:text>
	</xsl:template>

  <xsl:template match="xs:complexType|xs:simpleType">
    <xsl:if test="@name=$destType">
      <xsl:text>\begingroup
      	\renewcommand*\descriptionlabel[1]{%
      	\hbox to 5.5em{\emph{#1}\hfil}}</xsl:text>

      <xsl:if test="./xs:annotation/xs:documentation">
      	<xsl:text>\vspace{2ex}\noindent\textbf{\xmlel{</xsl:text>
      	<xsl:value-of select="concat(/xs:schema/xs:annotation/xs:appinfo/vm:targetPrefix,':',@name)"/>
      	<xsl:text>}</xsl:text>
      	<xsl:text> Type Schema Documentation}&#10;&#10;</xsl:text>
      	<xsl:apply-templates select="./xs:annotation/xs:documentation"
      		mode="typedesc"/>
      </xsl:if>
			
			<!-- oh my. refactor content.allowedValues stuff above to let us
			re-use the mess there here. -->
     	<xsl:if test="xs:restriction/xs:enumeration">
       	<xsl:text>\vspace{2ex}\noindent\textbf{\xmlel{</xsl:text>
      	<xsl:value-of select="concat(/xs:schema/xs:annotation/xs:appinfo/vm:targetPrefix,':',@name)"/>
      	<xsl:text>}</xsl:text>
      	<xsl:text> Type Allowed Values}&#10;&#10;\begin{longtermsdescription}</xsl:text>
       	<xsl:apply-templates 
       		select="descendant::xs:enumeration" 
       		mode="controlledVocab"/>
   			<xsl:text>\end{longtermsdescription}&#10;</xsl:text>
     	</xsl:if>

      <xsl:text>\vspace{1ex}\noindent\textbf{\xmlel{</xsl:text>
      <xsl:value-of select="concat(/xs:schema/xs:annotation/xs:appinfo/vm:targetPrefix,':',@name)"/>
      <xsl:text>}</xsl:text>
      <xsl:text> Type Schema Definition}&#10;&#10;</xsl:text>
      <xsl:apply-templates select="." mode="xsddef"/>

      <xsl:if test=".//xs:attribute">
        <xsl:text>&#10;&#10;\vspace{0.5ex}\noindent\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="attributeTitle"/>
        <xsl:text>}&#10;&#10;\begingroup\small\begin{bigdescription}</xsl:text>
        <xsl:apply-templates select="." mode="attributes"/>
        <xsl:text>&#10;\end{bigdescription}\endgroup&#10;&#10;</xsl:text>
      </xsl:if>

      <xsl:if test=".//xs:element">
        <xsl:text>&#10;&#10;\vspace{0.5ex}\noindent\textbf{</xsl:text>
        <xsl:apply-templates select="." mode="MetadataTitle"/>
        <xsl:text>}&#10;&#10;\begingroup\small\begin{bigdescription}</xsl:text>
        <xsl:apply-templates select="." mode="content"/>
        <xsl:text>&#10;\end{bigdescription}\endgroup&#10;&#10;</xsl:text>
      </xsl:if>
      <xsl:text>\endgroup</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
</xsl:stylesheet>
