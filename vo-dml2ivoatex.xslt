<?xml version="1.0"?>

<xsl:stylesheet version="1.0" 
       xmlns:vo-dml="http://www.ivoa.net/xml/VODML/v1"
       xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" >

<!-- 
  XSLT to translate VO-dml/XML content to an ivoatex file
  which can be inported to the primary document (${DOCNAME}.tex)

  * provides content for some of the Title Page elements
  * followed by the document body:
    o Section for Model and each Package
    o SubSection for each ObjectType, DataType, Enumeration, Primitive
    o SubSubSection for each type 'attribute' (attribute, composition, reference)
 -->

<xsl:output method="text" encoding="UTF-8" indent="yes" />
<xsl:strip-space elements="*" />

<!-- Main Template  -->
<xsl:template match="vo-dml:model">
  <xsl:apply-templates select="." mode="TitlePage"/>

  <xsl:apply-templates select="." mode="Section"/>

</xsl:template>

<!-- Title Page -->
<xsl:template match="vo-dml:model" mode="TitlePage">
% -------------------------------------------
% Items to substitute into the ivoatex document template.
%
%\ivoagroup{Data Model Working Group}

%\title{<xsl:value-of select="title"/>}

<xsl:call-template name="AuthorList">
   <xsl:with-param name="text" select="author"/>
</xsl:call-template>

<xsl:variable name="text"><xsl:value-of select="previousVersion"/></xsl:variable>
  <xsl:if test="string-length($text)">
    <xsl:choose>
      <xsl:when test="starts-with($text, 'http')">
%\previousversion[<xsl:value-of select="normalize-space($text)"/>]{}
      </xsl:when>
      <xsl:otherwise>
%\previousversion{<xsl:value-of select="normalize-space($text)"/>}
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
% -------------------------------------------
</xsl:template>

<!-- Section Template(s) -->
<xsl:template match="vo-dml:model" mode="Section">
\pagebreak
\section{Model: <xsl:value-of select="name"/> }
  <xsl:variable name="model_prefix"><xsl:value-of select="name"/>:</xsl:variable>
  % INSERT FIGURE HERE
  %\begin{figure}[h]
  %\begin{center}
  %  \includegraphics[width=\textwidth]{????.png}
  %  \caption{???}\label{fig:????}
  %\end{center}
  %\end{figure}

  <xsl:apply-templates select="." mode="Description"/>
  
  <xsl:for-each select="objectType|dataType">
    <xsl:sort select="name"/>
    <xsl:apply-templates select="." mode="SubSection"><xsl:with-param name="model_prefix" select="$model_prefix"/></xsl:apply-templates>
  </xsl:for-each>
  <xsl:apply-templates select="primitiveType" mode="SubSection"/>
  <xsl:apply-templates select="enumeration" mode="SubSection"/>
  
  <!-- check for packages -->
  <xsl:apply-templates select="package" mode="Section"/>
</xsl:template>

<xsl:template match="package" mode="Section">

\pagebreak
\section{Package: <xsl:value-of select="vodml-id"/> }

  % INSERT FIGURE HERE
  %\begin{figure}[h]
  %\begin{center}
  %  \includegraphics[width=\textwidth]{????.png}
  %  \caption{???}\label{fig:????}
  %\end{center}
  %\end{figure}

  <xsl:apply-templates select="." mode="Description"/>
  
  <xsl:for-each select="objectType|dataType">
    <xsl:sort select="name"/>
    <xsl:apply-templates select="." mode="SubSection"/>
  </xsl:for-each>
  <xsl:apply-templates select="primitiveType" mode="SubSection"/>
  <xsl:apply-templates select="enumeration" mode="SubSection"/>

  <!-- check for packages -->
  <xsl:apply-templates select="package" mode="Section"/>

</xsl:template>


<!-- Subsection Template -->
<xsl:template match="objectType|dataType" mode="SubSection">
  <xsl:param name="model_prefix"/>

  \subsection{<xsl:value-of select="name"/><xsl:apply-templates select="." name="abstract"/>}
  \label{sect:<xsl:value-of select="vodml-id"/>}
    <xsl:apply-templates select="." mode="Description"/>

  <xsl:if test="constraint[@xsi:type='vo-dml:SubsettedRole']">
    <xsl:apply-templates select="constraint[@xsi:type='vo-dml:SubsettedRole']" mode="Subsets"/>
  </xsl:if>
  <xsl:if test="constraint[not(@xsi:type='vo-dml:SubsettedRole')]">
    <xsl:apply-templates select="constraint[not(@xsi:type='vo-dml:SubsettedRole')]" mode="Constraints"/>
  </xsl:if>
    
    <xsl:for-each select="attribute|composition|reference">
      <xsl:apply-templates select="." mode="SubSubSection"><xsl:with-param name="model_prefix" select="$model_prefix"/></xsl:apply-templates>
    </xsl:for-each>
</xsl:template>

<xsl:template match="primitiveType" mode="SubSection">

  \subsection{<xsl:value-of select="name"/><xsl:apply-templates select="." name="abstract"/>}
  \label{sect:<xsl:value-of select="vodml-id"/>}
  <xsl:apply-templates select="." mode="Description"/>
</xsl:template>

<xsl:template match="enumeration" mode="SubSection">

  \subsection{<xsl:value-of select="name"/><xsl:apply-templates select="." name="abstract"/>}
  \label{sect:<xsl:value-of select="vodml-id"/>}

  <xsl:apply-templates select="." mode="Description"/>

  \noindent \underline{Enumeration Literals}
  \vspace{-\parsep}
  \small
  \begin{itemize}
  <xsl:for-each select="literal">
    <xsl:variable name="cname">
      <xsl:call-template name="Underscore">
	<xsl:with-param name="text" select="name"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="cvodml">
      <xsl:call-template name="Underscore">
	<xsl:with-param name="text" select="vodml-id"/>
      </xsl:call-template>
    </xsl:variable>
    \item[\textbf{<xsl:value-of select="$cname"/>}]: \textbf{vodml-id:} <xsl:value-of select="$cvodml"/> \newline
          \textbf{description:} <xsl:apply-templates select="." mode="Description"/>
  </xsl:for-each>
  \end{itemize}
  \normalsize
</xsl:template>


<!-- SubSubsection Template(s) -->
<xsl:template match="attribute|composition|reference" mode="SubSubSection">
    <xsl:param name="model_prefix"/>
    <xsl:variable name="isOrdered">
      <xsl:if test="./isOrdered"><xsl:value-of select="./isOrdered"/></xsl:if>
    </xsl:variable>

    <!-- generates internal reference to the element type in the PDF file -->
    <xsl:variable name="dtype"><xsl:value-of select="datatype/vodml-ref"/></xsl:variable>
    <xsl:variable name="typeWithRef">
      <xsl:choose>
	<xsl:when test="starts-with($dtype,'ivoa:')">\hyperref[sect:ivoa]{<xsl:value-of select="$dtype"/>}</xsl:when>
	<xsl:when test="starts-with($dtype, $model_prefix)">\hyperref[sect:<xsl:value-of select="substring-after($dtype,':')"/>]{<xsl:value-of select="$dtype"/>}</xsl:when>
	<xsl:otherwise><xsl:value-of select="$dtype"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="semanticconcept">

    \subsubsection{<xsl:value-of select="../name"/>.<xsl:value-of select="name"/>}
      \textbf{vodml-id: <xsl:value-of select="vodml-id"/>} \newline
      \textbf{type: <xsl:value-of select="$typeWithRef"/>} \newline
      \textbf{vocabulary: <xsl:value-of select="semanticconcept/vocabularyURI"/>} \newline
      \textbf{multiplicity: <xsl:apply-templates select="multiplicity" mode="tostring"/>} \newline
      </xsl:when>
      <xsl:otherwise>

    \subsubsection{<xsl:value-of select="../name"/>.<xsl:value-of select="name"/>}
      \textbf{vodml-id: <xsl:value-of select="vodml-id"/>} \newline
      \textbf{type: <xsl:value-of select="$typeWithRef"/>} \newline
      \textbf{multiplicity: <xsl:apply-templates select="multiplicity" mode="tostring"/> <xsl:if test="string-length($isOrdered)">  (ordered)</xsl:if>} \newline 
      </xsl:otherwise>
    </xsl:choose>
<xsl:apply-templates select="." mode="Description"/>
</xsl:template>

<!-- template to process Author list -->
<xsl:template name="AuthorList">
  <xsl:param name="text"/>
  <xsl:if test="string-length($text)">
    <xsl:variable name="item"><xsl:value-of select="substring-before(concat($text,','),',')"/></xsl:variable>
%\author{<xsl:value-of select="normalize-space($item)"/>}
    <xsl:call-template name="AuthorList">
      <xsl:with-param name="text" select="substring-after($text, ',')"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<!-- template to process description fields -->
<xsl:template match="*" mode="Description">
  <xsl:choose>
    <xsl:when test="description">
      <xsl:variable name="t1">
        <xsl:apply-templates select="description" name="Strip"/>
      </xsl:variable>
      <xsl:variable name="t2">
        <xsl:call-template name="Underscore">
          <xsl:with-param name="text" select="$t1"/>
	</xsl:call-template>
      </xsl:variable>
      <xsl:variable name="t3">
	<xsl:call-template name="Caret">
          <xsl:with-param name="text" select="$t2"/>
	</xsl:call-template>
      </xsl:variable>
      <xsl:call-template name="Ampersand">
        <xsl:with-param name="text" select="$t3"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>[TODO add description!]</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- template for constraints (subsetting)  -->
<xsl:template match="constraint" mode="Subsets">

    \noindent \textbf{subset} \newline
    \indent   \textbf{role: <xsl:value-of select="role/vodml-ref"/>} \newline
    \indent   \textbf{type: <xsl:value-of select="datatype/vodml-ref"/>} \newline
</xsl:template>

<!-- template for constraints (simple constraint)  -->
<xsl:template match="constraint" mode="Constraints">

    \noindent \textbf{constraint} \newline
    \indent    \textbf{detail: <xsl:value-of select="../name"/>.<xsl:value-of select="description"/> }\newline
</xsl:template>

<!-- template to convert multiplicity node into simple string -->
<xsl:template match="multiplicity" mode="tostring">
  <xsl:variable name="lower">
    <xsl:choose>
      <xsl:when test="minOccurs"><xsl:value-of select="minOccurs"/></xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="upper">
    <xsl:choose>
      <xsl:when test="not(maxOccurs)"><xsl:value-of select="'1'"/></xsl:when>
      <xsl:when test="number(maxOccurs) &lt; 0"><xsl:value-of select="'*'"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="maxOccurs"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="$lower = $upper"><xsl:value-of select="$lower"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="concat($lower,'..',$upper)"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- template test for Abstract Type -->
<xsl:template match="objectType|dataType|enumeration|primitiveType" name="abstract">
  <xsl:variable name="isAbstract"><xsl:value-of select="@abstract"/></xsl:variable>
  <xsl:if test="$isAbstract='true'"> (Abstract)</xsl:if>
</xsl:template>


<!-- ************ Generic Utility Templates ****************** -->

<!-- template to strips leading/trailing white space from text -->
<xsl:template match="text()" name="Strip">
  <xsl:value-of select='normalize-space()'/>
</xsl:template>

<!-- template to escape underscores in text -->
<!--   replace() is only in XSLT 2.0; got this substitute off the web and modified for this particular -->
<xsl:template name="Ampersand">
  <xsl:param name="text"/>
  <xsl:variable name="replace">&amp;</xsl:variable>
  <xsl:variable name="by">\&amp;</xsl:variable>
  <xsl:choose>
    <xsl:when test="contains($text,$replace)">
      <xsl:value-of select="substring-before($text,$replace)"/>
      <xsl:value-of select="$by"/>
      <xsl:call-template name="Ampersand">
        <xsl:with-param name="text" select="substring-after($text,$replace)"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="Caret">
  <xsl:param name="text"/>
  <xsl:variable name="replace">^</xsl:variable>
  <xsl:variable name="by">\^</xsl:variable>
  <xsl:choose>
    <xsl:when test="contains($text,$replace)">
      <xsl:value-of select="substring-before($text,$replace)"/>
      <xsl:value-of select="$by"/>
      <xsl:call-template name="Underscore">
        <xsl:with-param name="text" select="substring-after($text,$replace)"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="Underscore">
  <xsl:param name="text"/>
  <xsl:variable name="replace">_</xsl:variable>
  <xsl:variable name="by">\_</xsl:variable>
  <xsl:choose>
    <xsl:when test="contains($text,$replace)">
      <xsl:value-of select="substring-before($text,$replace)"/>
      <xsl:value-of select="$by"/>
      <xsl:call-template name="Underscore">
        <xsl:with-param name="text" select="substring-after($text,$replace)"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


</xsl:stylesheet>
