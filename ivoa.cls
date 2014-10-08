\ProvidesClass{ivoa}
\LoadClassWithOptions{article}

\NeedsTeXFormat{LaTeX2e}

\RequirePackage{calc}
\RequirePackage{graphicx}
\RequirePackage{xcolor}
\RequirePackage{ifthen}
\RequirePackage{doc}
\RequirePackage{paralist}
\RequirePackage{url}
\RequirePackage{natbib}

\definecolor{ivoacolor}{rgb}{0.0,0.318,0.612}
\definecolor{linkcolor}{rgb}{0.318,0,0.318}

\RequirePackage[colorlinks,
	linkcolor=linkcolor,
	anchorcolor=linkcolor,
	citecolor=linkcolor,
	pagecolor=linkcolor,
	urlcolor=linkcolor]{hyperref}

\bibliographystyle{agsm}

\DeclareGraphicsRule{.pdffig}{pdf}{.pdffig}{}

\makeatletter

%%%%%%%%%%%%%%%%%%% Metadata definition macros

\newcommand{\ivoagroup}[1]{\def\ivo@group{#1}}
\newcommand{\editor}[1]{\def\@ditor{#1}}

% these are accumulators for sequences
\def\previ@usversions{}
\def\@uthors{}

\renewcommand{\author}[2][0]{%
	\ifthenelse{\equal{\@uthors}{}}{}
		{\g@addto@macro\@uthors{, }}
	\ifthenelse{\equal{#1}{0}}
	{\g@addto@macro\@uthors{#2}}
	{\g@addto@macro\@uthors{\href{#1}{#2}}}}
\newcommand{\previousversion}[2][0]{
	\ifthenelse{\equal{#1}{0}}
	{\g@addto@macro\previ@usversions{\item #2}}
	{\g@addto@macro\previ@usversions{\item \href{#1}{#2}}}}

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
  \noindent{\LARGE\color{ivoacolor}\sffamily\bfseries \@title}

	\medskip
  \noindent{\LARGE\color{ivoacolor}\sffamily\bfseries 
  	Version \ivoaDocversion}
	\bigskip
  \titlehe@d{\expandedDoctype{\ivoaDoctype} \ivoaDocdate}%


  \begin{bigdescription}
    \item[Working group]
    	\ivo@group

    \item[This version]
    	\currentDocURL

    \item[Latest version]
    	\latestDocURL

    \item[Previous versions]
			\begin{compactenum}[]
				\previ@usversions
			\end{compactenum}

    \item[Author(s)]
    	\begin{compactenum}[]
      	\@uthors
    	\end{compactenum}

    \item[Editor(s)]
    	\@ditor
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
    \titlehe@d{Status of This Document}

   	\medskip
   	\docstatusDeclaration{\ivoaDoctype}
   	\tableofcontents}


\newcommand\expandedDoctype[1] % "Proposed Recommendation" for PR and such
	{\ifthenelse{\equal{#1}{NOTE}}
		{IVOA Note}
		{\ifthenelse{\equal{#1}{WD}}
			{IVOA Working Draft}
			{\ifthenelse{\equal{#1}{PR}}
				{IVOA Proposed Recommendation}
				{\ifthenelse{\equal{#1}{REC}}
					{IVOA Recommendation}
					{UNKNOWN DOCUMENT (fix DOCTYPE)}}}}}

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
					{UNKNOWN DOCUMENT (fix DOCTYPE)}}}}\par
	A list of current IVOA Recommendations and other technical documents
	can be found at \href{http://www.ivoa.net/Documents/
	}{http://www.ivoa.net/Documents/}.}


\newcommand\currentDocURL % URL of this document's landing page
	{\href{http://www.ivoa.net/documents/\ivoaDocname/\ivoaDocdatecode}
		{http://www.ivoa.net/documents/\ivoaDocname/\ivoaDocdatecode}}
\newcommand\latestDocURL 
	% URL of a potential successor to the document's landing page
	{\href{http://www.ivoa.net/documents/\ivoaDocname}
		{http://www.ivoa.net/documents/\ivoaDocname}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Styling various item

\renewcommand\section{\@startsection {section}{1}{\z@}%
                                   {-3.5ex \@plus -1ex \@minus -.2ex}%
                                   {2.3ex \@plus.2ex}%
                                   {\raggedright\normalfont\Large
                                   \color{ivoacolor}\bfseries\sffamily}}
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
                                     {-3.25ex\@plus -1ex \@minus -.2ex}%
                                     {1.5ex \@plus .2ex}%
                                     {\normalfont\large
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
  \begin{table} %% TBD: use a different sort of insertion env?
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

\newcommand{\xmlel}[1]{{\ttfamily\itshape #1}}

\makeatother

\input ivoatexmeta.tex
