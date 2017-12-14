<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT to generate SVG for architecture diagrams. 

This processes documents having the following structure

<archdiag xmlns="http://ivoa.net/archdiag">
	<rec name="SAMP" x="10" y="14"/>
	<prerec name="FOP" x="10" y="34"/>  (a REC not yet passed)
</archdiag>

Recommendation: Start with archdiag-full.xml and remove standards you don't
want.
-->

<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns="http://www.w3.org/2000/svg" 
	xmlns:ad="http://ivoa.net/archdiag"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	version="1.0">

<xsl:template name="format-standard">
	<xsl:param name="std-name"/>
	<xsl:param name="std-class"/>
	<xsl:param name="x0"/>
	<xsl:param name="y0"/>

	<svg>
		<xsl:attribute name="x">
			<xsl:value-of select="$x0"/>
		</xsl:attribute>
		<xsl:attribute name="y">
			<xsl:value-of select="$y0"/>
		</xsl:attribute>
		<rect width="90" height="18" x="0" y="0">
			<xsl:attribute name="class">
				<xsl:value-of select="$std-class"/>
			</xsl:attribute>
		</rect>
		<text class="doclabel" x="45" y="14"
			><xsl:value-of select="$std-name"/></text>
	</svg>
</xsl:template>

<xsl:template match="ad:rec">
	<xsl:call-template name="format-standard">
		<xsl:with-param name="x0" select="@x"/>
		<xsl:with-param name="y0" select="@y"/>
		<xsl:with-param name="std-name" select="@name"/>
		<xsl:with-param name="std-class">rec</xsl:with-param>
	</xsl:call-template>
</xsl:template>

<xsl:template match="ad:prerec">
	<xsl:call-template name="format-standard">
		<xsl:with-param name="x0" select="@x"/>
		<xsl:with-param name="y0" select="@y"/>
		<xsl:with-param name="std-name" select="@name"/>
		<xsl:with-param name="std-class">prerec</xsl:with-param>
	</xsl:call-template>
</xsl:template>

<xsl:template match="ad:archdiag">
	<!-- design size: 800 x 600 whateever; 50 border for annotation-->
	<svg  version="2.0"
		width="800" height="600">
		<defs>
			<style type="text/css">
				rect.rec {
					fill: #bbe0e3;
					stroke: #0000ff;
				}

				rect.prerec {
					fill: #bbe0e3;
					stroke: none;
				}

				text.doclabel {
					fill: #0000ff;
					font-family: univers;
					font-size: 10px;
					text-anchor:middle;
				}
			</style>
		</defs>

		<title>IVOA Architecture Diagram</title>
		<desc>This image shows the architecture of the Virtual Observatory
		(cf. http://ivoa.net), together with the relevant standards.</desc>

		<!-- outer frame -->
		<rect x="50" y="50" width="700" height="500"
			style="stroke:black;fill:white;"/>

		<!-- inner separator lines -->
		<g style="stroke:black;stroke-dasharray:5,2">
		<line id="user_layer_sep" x1="50" y1="100" x2="750" y2="100"/>
		<line id="resource_layer_sep" x1="50" y1="500" x2="750" y2="500"/>
		</g>
		<g style="stroke:black;stroke-dasharray:5,5;stroke-width:0.5">
		<line id="using_sep" x1="50" y1="150" x2="750" y2="150"/>
		<line id="sharing_sep" x1="50" y1="450" x2="750" y2="450"/>
		<line id="registry_sep" x1="150" y1="100" x2="150" y2="500"/>
		<line id="dal_sep" x1="650" y1="100" x2="650" y2="500"/>
		</g>


		<!-- border annotation -->
		<g style="font-size:16px;font-family:sans-serif;
			text-anchor:middle;text-align:center;font-weight:bold">
		<text x="250" y="25">Users</text>
		<text x="550" y="25">Computers</text>
		<g class="level1">
		<text x="25" y="300" transform="rotate(-90, 25, 300)">Registry</text>
		<text x="775" y="300" transform="rotate(90, 775, 300)"
			>Data Access Protocols</text>
		<text x="400" y="585">Providers</text>
		</g>
		</g>

		<!-- level 0 annotation -->
		<g style="font-size:20px;font-family:sans-serif;fill:#888888;
			text-anchor:middle;text-align:center">
			<text x="400" y="72">User Layer</text>
			<text x="400" y="132">Using</text>
			<text x="400" y="543">Resource Layer</text>
			<text x="400" y="480">Sharing</text>
			<text x="400" y="300">VO Core</text>
			<text x="100" y="300" transform="rotate(-90, 100, 300)">Finding</text>
			<text x="700" y="300" transform="rotate(90, 700, 300)"
				>Getting</text>
		</g>

		<!-- level 1 annotation -->
		<g class="level1">
			<g style="font-size:16px;font-family:sans-serif;
				text-anchor:middle;text-align:center;font-style:italic">
				<text x="400" y="96">Desktop Apps</text>
				<text x="175" y="96">In-Browser Apps</text>
				<text x="625" y="96">User Programs</text>

				<text x="400" y="520">Data and Metadata Collection</text>
				<text x="175" y="520">Storage</text>
				<text x="625" y="520">Computation</text>

				<text x="250" y="300">Semantics</text>
				<text x="550" y="300">Data Models</text>

				<text x="400" y="225">VO Query Languages</text>
				<text x="400" y="375">Formats</text>
			</g>
		</g>

		<!-- level 2: standards -->

		<g class="level2">
			<xsl:apply-templates/>
		</g>
	</svg>
</xsl:template>
</xsl:stylesheet>
