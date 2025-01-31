\ProvidesClass{ivoa}
\LoadClassWithOptions{article}

\NeedsTeXFormat{LaTeX2e}

\RequirePackage{calc}
\RequirePackage{graphicx}
\RequirePackage{xcolor}
\RequirePackage{ifthen}
\RequirePackage{listings}
\RequirePackage{textcomp}
\RequirePackage{paralist}
\RequirePackage{url}
\RequirePackage[nottoc]{tocbibind}
\RequirePackage[labelfont=it]{caption}
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}

\definecolor{ivoacolor}{rgb}{0.0,0.318,0.612}
\definecolor{linkcolor}{rgb}{0.318,0,0.318}

\RequirePackage[colorlinks,
	linkcolor=linkcolor,
	anchorcolor=linkcolor,
	citecolor=linkcolor,
	urlcolor=linkcolor,
	breaklinks=true]{hyperref}

\RequirePackage{natbib}
\bibliographystyle{ivoatex/ivoa}

% people usually want to cut and paste from our listings, so keep
% lstlistings from mangling quotes.
\lstset{upquote=true}

\urlstyle{same}

\renewcommand{\topfraction}{0.9}
\renewcommand{\bottomfraction}{0.7}
\renewcommand{\textfraction}{0.1}
\renewcommand{\floatpagefraction}{0.8}

\setlength{\parskip}{1pt plus 2pt}

\makeatletter

%%%%%%%%%%%%%%%%%%% Metadata definition macros

\newcommand{\ivoagroup}[2][WG]{%
	\def\ivo@group{#2}%
	\ifthenelse{\equal{#1}{IG}}
		{\gdef\gr@uptype{Interest Group}}
		{\gdef\gr@uptype{Working Group}}
}

% these are accumulators for sequences
\def\previ@usversions{}
\def\@uthors{}
\def\@ditors{}

\renewcommand{\author}[2][0]{%
	\ifthenelse{\equal{\@uthors}{}}{}
		{\g@addto@macro\@uthors{, }}
	\ifthenelse{\equal{#1}{0}}
	{\g@addto@macro\@uthors{#2}}
	{\g@addto@macro\@uthors{\href{#1}{#2}}}}
\newcommand{\editor}[2][0]{%
        \ifthenelse{\equal{\@ditors}{}}{}
                {\g@addto@macro\@ditors{, }}
        \ifthenelse{\equal{#1}{0}}
        {\g@addto@macro\@ditors{#2}}
        {\g@addto@macro\@ditors{\href{#1}{#2}}}}
\newcommand{\previousversion}[2][0]{
	\ifthenelse{\equal{#1}{0}}
	{\g@addto@macro\previ@usversions{\item #2}}
	{\g@addto@macro\previ@usversions{\item \href{#1}{#2}}}}

\def\vcsR@vision{unknown}
\def\vcsD@te{unknown}
\def\vcs@RL{unknown}
\newcommand{\vcsrevision}[1]{\gdef\vcsR@vision{#1}}
\newcommand{\vcsdate}[1]{\gdef\vcsD@te{#1}}
\newcommand{\vcsurl}[1]{\gdef\vcs@RL{#1}}

\def\SVN$#1: #2 ${%
	\ifthenelse{\equal{#1}{Date}}
		{\vcsdate{#2}}{%
	\ifthenelse{\equal{#1}{Rev}}
		{\vcsrevision{#2}}{%
	\ifthenelse{\equal{#1}{URL}}
		{\vcsurl{#2}}{%
	\message{Invalid SVN key /#1/}}
}}}

%%%%%%%%%%%%%%%%%% Tools for formatting the titlepage

\newcommand*\bigdescriptionlabel[1]{%
	\parbox[b]{\labelwidth}{\makebox[0pt][l]{\color{ivoacolor}#1}\\\mbox{}}}
\newenvironment{bigdescription}%
	{\begin{list}{}{%
		\setlength{\leftmargin}{4em}
		\setlength{\labelwidth}{4em}
		\setlength{\labelsep}{0pt}
		\setlength{\listparindent}{0pt}
		\setlength{\itemsep}{0pt}
		\let\makelabel\bigdescriptionlabel}
		\let\term\item
	}{%
		\end{list}}

\newcommand*\longtermslabel[1]{%
	\parbox[b]{\labelwidth}{\makebox[0pt][l]{#1}\\\mbox{}}}
\newenvironment{longtermsdescription}%
	{\begin{list}{}{%
		\setlength{\leftmargin}{4em}
		\setlength{\labelwidth}{4em}
		\setlength{\labelsep}{0pt}
		\setlength{\listparindent}{0pt}
		\setlength{\itemsep}{3pt}
		\let\makelabel\longtermslabel}
		\let\term\item
	}{%
		\end{list}}

\newcommand\titlehe@d[1]{\bigbreak{\noindent
	\Large\color{ivoacolor}\sffamily\bfseries #1}\nobreak\par\nobreak}

\renewcommand\maketitle{
  \let\footnotesize\small
  \let\footnoterule\relax
  \let \footnote \thanks
  \mbox{}
  \vskip -2cm
  \noindent\mbox{%
  \includegraphics[width=6cm]{ivoatex/IVOA.jpg}%
  \raisebox{1.5cm}{\parbox{5cm}{
    \Large\color{ivoacolor}\textsl{\textsf{\textbf{I}nternational}} \\
    \Large\color{ivoacolor}\quad\textsl{\textsf{\textbf{V}irtual}} \\
    \Large\color{ivoacolor}\quad\textsl{\textsf{\textbf{O}bservatory}} \\
    \Large\color{ivoacolor}\textsl{\textsf{\textbf{A}lliance}}}}\hfil}

 	\vskip 1.4cm
 	\begin{sloppypar}\raggedright
  \LARGE\color{ivoacolor}\sffamily\bfseries \@title\par
  \end{sloppypar}

	\bigskip
  \noindent{\LARGE\color{ivoacolor}\sffamily\bfseries
  	Version \ivoaDocversion}
	\medskip
  \titlehe@d{\expandedDoctype{\ivoaDoctype} \ivoaDocdate}%


  \begin{bigdescription}
    \item[\gr@uptype]
    	\ivo@group

    \item[This version]
    	\currentDocRef

    \item[Latest version]
    	\latestDocRef

    \item[Previous versions]
			\begin{compactitem}[]
				\previ@usversions
			\end{compactitem}

    \item[Author(s)]
    	\begin{compactitem}[]
      	\@uthors
    	\end{compactitem}

    \item[Editor(s)]
        \begin{compactitem}[]
    	\@ditors
        \end{compactitem}

    \ifthenelse{\equal{\vcsR@vision}{unknown}}{\relax}{
    	\item[Version Control]
    		Revision \vcsR@vision
    			\ifthenelse{\equal{\vcsD@te}{unknown}}{\relax}{,
    				\vcsD@te}
   				\ifthenelse{\equal{\vcs@RL}{unknown}}{\relax}
   					{\\\strut\tiny\url{\vcs@RL}}}
    			
    \end{bigdescription}
  \@thanks
  \vfill\null
  \setcounter{footnote}{0}%
}



\renewenvironment{abstract}{%
    \thispagestyle{empty}
    \maketitle
    \@beginparpenalty\@lowpenalty
    \titlehe@d{\abstractname}
    \medskip
    \@endparpenalty\@M}
    {\par
    \bigskip
    \titlehe@d{Status of this document}

   	\medskip
   	\docstatusDeclaration{\ivoaDoctype}
   	\tableofcontents}

\newenvironment{generated}{%
	\list{}{\rightmargin 0mm\leftmargin 5mm}\item[]}
	{\endlist}

\newcommand\expandedDoctype[1] % "Proposed Recommendation" for PR and such
	{\ifthenelse{\equal{#1}{NOTE}}
		{IVOA Note}
		{\ifthenelse{\equal{#1}{WD}}
			{IVOA Working Draft}
		{\ifthenelse{\equal{#1}{PR}}
			{IVOA Proposed Recommendation}
		{\ifthenelse{\equal{#1}{REC}}
			{IVOA Recommendation}
		{\ifthenelse{\equal{#1}{PEN}}
			{Proposed Endorsed Note}
		{\ifthenelse{\equal{#1}{EN}}
			{Endorsed Note}
		{UNKNOWN DOCUMENT (fix DOCTYPE)}}}}}}}

\newcommand\docstatusDeclaration[1]
	{\ifthenelse{\equal{#1}{NOTE}}
		{This is an IVOA Note expressing suggestions from and
     opinions of the authors. It is intended to share best
     practices, possible approaches, or other perspectives on
     interoperability with the Virtual Observatory. It should
     not be referenced or otherwise interpreted as a standard
     specification.}
	{\ifthenelse{\equal{#1}{WD}}
		{This is an IVOA Working Draft for review by IVOA members
     and other interested parties.  It is a draft document and
     may be updated, replaced, or obsoleted by other documents
     at any time. It is inappropriate to use IVOA Working Drafts
     as reference materials or to cite them as other than ``work
     in progress''.}
 	{\ifthenelse{\equal{#1}{PR}}
 		{This is an IVOA Proposed Recommendation made available for
      public review. It is appropriate to reference this document
      only as a recommended standard that is under review and
      which may be changed before it is accepted as a full
      Recommendation.}
 	{\ifthenelse{\equal{#1}{PEN}}
 		{This is an IVOA Proposed Endorsed Note for review by IVOA
      members and other interested parties. It is appropriate to
      reference this document only as a Proposed Endorsed Note that
      is under review and may change before it is endorsed or may
      not be endorsed.
 		}
 	{\ifthenelse{\equal{#1}{EN}}
 		{This document is an IVOA Endorsed Note. It has been reviewed  and endorsed
 			by the IVOA Technical Coordination Group as a stable, citable document
 			which constitutes valuable information for the IVOA community and
 			beyond.
 		}
	{\ifthenelse{\equal{#1}{REC}}
		{This document has been reviewed by IVOA Members and other
     interested parties, and has been endorsed by the IVOA
     Executive Committee as an IVOA Recommendation. It is a
     stable document and may be used as reference material or
     cited as a normative reference from another document.
     IVOA's role in making the Recommendation is to draw
     attention to the specification and to promote its
     widespread deployment. This enhances the functionality and
     interoperability inside the Astronomical Community.}
		{UNKNOWN DOCUMENT TYPE (fix DOCTYPE)}}}}}}\par
	A list of current IVOA Recommendations and other technical documents
	can be found in the IVOA document
	repository\footnotemark\footnotetext{\url{https://www.ivoa.net/documents/}}.}

% legacy definition when ivoatexmeta.tex does not yet define it
\newcommand{\ivoaBaseURL}{https://www.ivoa.net/documents/\ivoaDocname}
\newcommand\currentDocURL %
	{\ivoaBaseURL/\ivoaDocdatecode}
\newcommand\currentDocRef % formatted reference to this document's landing page
	{\href{\currentDocURL}{\currentDocURL}}
\newcommand\latestDocRef
	% formatted reference to a potential successor to the document's landing page
	{\href{\ivoaBaseURL}{\ivoaBaseURL}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Styling various item

\renewcommand\section{\@startsection {section}{1}{\z@}%
                                   {-3.5ex \@plus -1ex \@minus -.2ex}%
                                   {2.3ex \@plus.2ex}%
                                   {\raggedright\normalfont\Large
                                   \color{ivoacolor}\bfseries\sffamily}}
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
                                     {-3.25ex\@plus -1ex \@minus -.2ex}%
                                     {1.5ex \@plus .2ex}%
                                     {\raggedright\normalfont\large
                                     \color{ivoacolor}\bfseries\sffamily}}
\renewcommand\subsubsection{\@startsection{subsubsection}{3}{\z@}%
                                     {-3.25ex\@plus -1ex \@minus -.2ex}%
                                     {1.5ex \@plus .2ex}%
                                     {\normalfont\normalsize
                                     \color{ivoacolor}\bfseries\sffamily}}
\renewcommand\paragraph{\@startsection{paragraph}{4}{\z@}%
                                    {3.25ex \@plus1ex \@minus.2ex}%
                                    {-1em}%
                                    {\normalfont\normalsize
                                    \color{ivoacolor}\bfseries\sffamily}}
\renewcommand\subparagraph{\@startsection{subparagraph}{5}{\parindent}%
                                       {3.25ex \@plus1ex \@minus .2ex}%
                                       {-1em}%
                                      {\normalfont\normalsize\bfseries}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Various utilities for writing IVOA docs

\newenvironment{admonition}[1]{ % a simple admonition box
  \begin{table}[ht] %% TBD: use a different sort of insertion env?
  \hskip -0.75cm
  \begin{minipage}[r]{0.75\columnwidth}%
  {\color{lightgray}\hrule}
  \medskip
  \hfil
  \begin{minipage}[c]{0.9\columnwidth}
  \small
  \makebox[\columnwidth][l]{\sffamily\bfseries\color{ivoacolor}#1}%
  \par\smallskip
  \noindent\raggedright\ignorespaces
  }%
  {%
  \end{minipage}
  \hfil
  \medskip
  {\color{lightgray}\hrule}
  \end{minipage}%
  \end{table}
  }%


\newenvironment{inlinetable}{\vskip 1.5ex plus 0.5ex minus 0.5ex
		\vfil\penalty8000\vfilneg%
    \hbox to\hsize\bgroup\hss}
  {\hss\egroup\vspace{8pt}}

% customcss only relevant for tth output, not LaTeX
\newcommand{\customcss}[1]{\relax}

\newcommand{\xmlel}[1]{{\ttfamily\itshape #1}}
\newcommand{\vorent}[1]{\textsc{#1}}
\def\ucd{\st@rtucd\re@lucd}
\def\re@lucd#1{\sl#1\@nducd}
\begingroup
% let LaTeX break UCD componds and at dots and semicolons in UCDs
\gdef\bre@kabledot{.\hskip0pt}
\gdef\bre@kablesemicolon{;\hskip0pt}
\catcode`\.=\active\catcode`\;=\active
\gdef\st@rtucd{\begingroup
  \catcode`\.=\active\let.=\bre@kabledot
  \catcode`\;=\active\let;=\bre@kablesemicolon}
\gdef\@nducd{\endgroup}
\endgroup

\newcommand{\sptablerule}{\noalign{\vspace{2pt}}\hline\noalign{\vspace{2pt}}}

\newcommand{\ivoatex}{\mbox{\textsc{Ivoa}\TeX}}

\newcommand{\auxiliaryurl}[1]{\href{\currentDocURL/#1}{\currentDocURL/#1}}

\chardef\dquote'042

\newcommand{\tikzfigure}[1]{\input{#1.tikz.tex}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Changing LaTeX/package defaults

\renewcommand*\descriptionlabel[1]
	{\hspace{\labelsep}\itshape #1}

\lst@CCPutMacro
    \lst@ProcessOther {"2D}{\lst@ttfamily{-{}}{-}}
    \@empty\z@\@empty

\makeatother

\input aas_macros.tex
\input ivoatexmeta.tex
