<?xml version="1.0"?>
<stylesheet version="1.0"
	xmlns:h="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/XSL/Transform" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions">

<!-- XSLT for a partial automation of the migration from ivoadoc 
XHTML to ivoatex -->

<output method="text"/>
<strip-space elements="*"/>

<template match="h:html">
\documentclass{ivoa}
\input tthdefs


\ivoagroup{FIXTHIS}

\author[FIXTHIS]{FIXTHIS}

\editor[FIXTHIS]{FIXTHIS}

\previousversion{FIXTHIS}

<apply-templates/>
</template>

<template match="h:p">
	<apply-templates/>
	<text>&#xa;&#xa;</text>
</template>

<template match="h:body">
\begin{document}
<apply-templates/>
\end{document}
</template>

<!-- Common inline markup -->

<template match="h:cite">\citep{<apply-templates/>}</template>

<template match="h:em">\emph{<apply-templates/>}</template>

<template match="h:strong">\textbf{<apply-templates/>}</template>

<template match="h:span[@class='xref']">\ref{<apply-templates/>}</template>

<template match="h:code">\texttt{<apply-templates/>}</template>

<template match="h:a[@href]"
	>\href{<value-of select="@href"/>}{<apply-templates/>}</template> 

<template match="h:br">\\</template>


<!-- Tables (these will definitely require polishing) -->

<template match="h:table">
\begin{table}
\begin{tabular}[FIXTHIS]
<apply-templates/>
\end{tabular}
\end{table}
</template>

<template match="h:tr">
<apply-templates/>\\
</template>

<template match="h:td[position()!=last()]">
<apply-templates/>&amp;</template>

<template match="h:td[position()=last()]">
<apply-templates/></template>

<template match="h:th[position()!=last()]">
\textbf{<apply-templates/>}&amp;</template>

<template match="h:th[position()=last()]">
\textbf{<apply-templates/>}</template>

<template match="h:tbody"><apply-templates/></template>
<template match="h:thead"><apply-templates/></template>

<template match="h:div[@class='tablewrap']"><apply-templates/></template>

<!-- Images and other block-level stuff -->

<template match="h:img">
\includegraphics[width=0.9\textwidth]{<value-of select="src"/>}
</template>

<template match="h:div[@class='figure']">
\begin{figure}
<apply-templates/>

FIXTHIS: Mark up caption
\end{figure}
</template>

<template match="h:dl">
\begin{description}
<apply-templates/>
\end{description}

</template>

<template match="h:dt">\item[<apply-templates/>]</template>

<template match="h:dd"><apply-templates/><text>&#x0a;</text></template> 

<template match="h:pre">
\begin{verbatim}<apply-templates/>\end{verbatim}

</template>

<template match="h:ul">
\begin{itemize}
<apply-templates/>
\end{itemize}
</template>

<template match="h:ol">
\begin{enumerate}
<apply-templates/>
\end{enumerate}
</template>

<template match="h:li">
\item <apply-templates/>{}
</template>

<!-- Sectioning -->

<template match="h:h2">
\section{<apply-templates/>}
<apply-templates mode="extract-labels"/>
</template>

<template match="h:h3">
\subsection{<apply-templates/>}
<apply-templates mode="extract-labels"/>
</template>

<template match="h:h4">
\subsubsection{<apply-templates/>}
<apply-templates mode="extract-labels"/>
</template>

<template match="h:a" mode="extract-labels">
\label{<value-of select="@id"/>}

</template>

<template match="h:a[@name]"><!-- 
	we have no idea what to do with a random anchor --><apply-templates
/></template>

<template match="h:a[@id]"><!-- 
	we have no idea what to do with a random anchor --><apply-templates
/></template>


<template match="h:div[@class='section']">
% HTML section start
<apply-templates/>
% HTML section ends
</template>

<!-- Pull some stuff from the document header, throw away the rest -->

<template match="h:div[@class='head']">
	<apply-templates mode="head"/>
</template>

<template match="h:h2[text()='Abstract']" mode="head">
\begin{abstract}
<variable name="myPos" select="position()"/>
<apply-templates select="../*[$myPos+1]"/>
\end{abstract}

</template>

<template match="h:head">
\title{<value-of select="h:title"/>}
</template>

<template match="*" mode="head">
</template>


<!-- Fallback so unmapped stuff doesn't just vanish -->

<template match="*" priority="-10">
&lt;<value-of select="local-name()"/>&gt;<apply-templates
	/>&lt;/<value-of select="local-name()"/>&gt;
</template>


<!-- other stuff -->

<template match="comment()">
% <value-of select="normalize-space(.)"/><text>&#x0a;</text>
</template>


</stylesheet>
